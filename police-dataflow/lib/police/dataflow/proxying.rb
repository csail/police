module Police

module DataFlow

# The complex method dispatching logic used by ProxyBase.
#
# ProxyBase is the superclass for all proxy classes, which makes it visible to
# application code. For this reason, we avoid defining any methods there.
require 'police/vminfo'

module Proxying
  # Creates a label-holding proxy for an object.
  #
  # @param [Object] proxied the object to be proxied
  # @param [Hash<Integer,Hash<Police::DataFlow::Label,Boolean>>] label_set the
  #     set of all labels that will be held by the object's proxy
  # @return [Police::DataFlow::ProxyBase] an object that can carry labels, and
  #     performs label-propagation as it redirects received messages to the
  #     proxied object
  def self.proxy(proxied, label_set)
    proxy_class = Police::DataFlow::Proxies.for proxied.class, label_set
    proxy_class.new proxied, proxy_class, label_set
  end

  # Creates proxies for a class' instance methods.
  #
  # The proxy methods are defined as instance methods for the proxying class,
  # because all the proxied objects that have the same class will need the same
  # proxies.
  #
  # @param [Class] proxy_class a Police::DataFlow::Proxy subclass that will
  #     receive the new proxy method definitions
  # @param [Class] klass the class whose instance methods will be proxied
  # @return [NilClass] nil
  def self.add_instance_methods(proxy_class, klass)
    # NOTE: this is thread-safe because, at worst, the effort of adding methods
    #       will be re-duplicated
    klass.public_instance_methods(true).each do |method|
      add_instance_method proxy_class, klass.instance_method(method), :public
    end
    klass.protected_instance_methods(true).each do |method|
      add_instance_method proxy_class, klass.instance_method(method),
                          :protected
    end
    klass.private_instance_methods(true).each do |method|
      add_instance_method proxy_class, klass.instance_method(method), :private
    end
    nil
  end

  # Adds a method to a proxy class.
  #
  # @param [Module] proxy_class the class that will receive the proxy method
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  def self.add_instance_method(proxy_class, method_def, access)
    # Avoid redefining methods, because that blows up VM caches.
    if proxy_class.method_defined?(method_def.name) ||
        proxy_class.private_method_defined?(method_def.name)
      return
    end

    # Define the method.
    proxy_class.class_eval proxy_method_definition(
        proxy_class.__police_classes__, method_def, access)
    # Set its access level.
    proxy_class.__send__ access, method_def.name
  end

  # The full definition of a proxy method.
  #
  # @param [Array<Police::DataFlow::Label>] label_classes the label classes
  #     supported by the proxy class
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  # @return [String] a chunk of Ruby that can be eval'ed in the context of a
  #     proxy class to define a proxy for the given method
  def self.proxy_method_definition(label_classes, method_def, access)
    # NOTE: it might be tempting to attempt to pass a block to the proxied
    #       method at all times, and try to yield to the original block when
    #       our block is invoked; this would work most of the time, but it
    #       would break methods such as Enumerable#map and String#scan, whose
    #       behavior changes depending on whether or not a block is passed to
    #       them
    ["def #{method_def.name}(#{proxy_argument_list(method_def, true)})",
       proxy_sticky_fastpath_check(method_def),
       proxy_sticky_gathering(method_def),
       "return_value = if block",
         proxy_method_call(method_def, access) + " do |*yield_args|",
           proxy_yield_sticky_decorating(method_def),
           proxy_yield_args_decorating(label_classes, method_def),
           "block_return = yield(*yield_args)",
           # TODO(pwnall): consider adding a yield value filter
           "next block_return",
         "end",
       "else",
         proxy_method_call(method_def, access),
       "end",

       proxy_return_sticky_decorating(method_def),
       proxy_return_decorating(label_classes, method_def),
       "return return_value",
     "end"].join ';'
  end

  # The proxying call to a method.
  #
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  # @return [String] a chunk of Ruby that can be used to call the given method
  #     when defining a proxy for it
  def self.proxy_method_call(method_def, access)
    arg_list = proxy_call_argument_list method_def

    if access == :public
      "@__police_proxied__.#{method_def.name}(#{arg_list})"
    else
      if arg_list.empty?
        "@__police_proxied__.__send__(:#{method_def.name})"
      else
        "@__police_proxied__.__send__(:#{method_def.name}, #{arg_list})"
      end
    end
  end

  # Code that labels the values yielded by a decorated method to its block.
  #
  # @param [Array<Police::DataFlow::Label>] label_classes the label classes
  #     supported by the proxy class
  # @param [Method] method_def the definition of the decorated method
  # @return [String] a chunk of Ruby that can be used to invoke the yield args
  #     decorators of the labels held by a labeled object's proxy
  def self.proxy_yield_args_decorating(label_classes, method_def)
    method_name = method_def.name
    arg_list = proxy_argument_list method_def, false
    code_lines = ['labels = @__police_labels__']
    label_classes.each do |label_class|
      if hook = label_class.yield_args_hook(method_name)
        label_key = label_class.__id__
        code_lines << "labels[#{label_key}].each { |label, _| " \
            "label.#{hook}(self, yield_args, #{arg_list}) }"
      elsif label_class.sticky?
        label_key = label_class.__id__
        code_lines << "labels[#{label_key}].each { |label, _| " \
            "yield_args.map! { |arg| ::Police::DataFlow.label(arg, label) } " \
            "}"
      end
    end
    (code_lines.length > 1) ? code_lines.join('; ') : ''
  end

  # Code that labels return value of a decorated method.
  #
  # @param [Array<Police::DataFlow::Label>] label_classes the label classes
  #     supported by the proxy class
  # @param [Method] method_def the definition of the method to be proxied
  # @return [String] a chunk of Ruby that can be used to invoke the return
  #     value decorators of the labels held by a labeled object's proxy
  def self.proxy_return_decorating(label_classes, method_def)
    method_name = method_def.name
    arg_list = proxy_argument_list method_def, false
    code_lines = ['labels = @__police_labels__']
    label_classes.each do |label_class|
      if hook = label_class.return_hook(method_name)
        label_key = label_class.__id__
        code_lines << "labels[#{label_key}].each { |label, _| " \
            "return_value = label.#{hook}(return_value, self, #{arg_list}) }"
      elsif label_class.sticky?
        label_key = label_class.__id__
        code_lines << "labels[#{label_key}].each { |label, _| " \
            "return_value = ::Police::DataFlow.label(return_value, label) }"
      end
    end
    (code_lines.length > 1) ? code_lines.join('; ') : ''
  end

  # The list of arguments used to define a proxy for the given method.
  #
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Boolean] captue_block if true, the method captures the block that
  #     it receives; this should be true when the returned code is used in
  #     method definitions, and false when it is used in method calls
  # @return [String] a chunk of Ruby that can be used as the argument list when
  #     defining a proxy for the given method
  def self.proxy_argument_list(method_def, capture_block)
    arg_list = if method_def.arity >= 0
      # Fixed number of arguments.
      (1..method_def.arity).map { |i| "arg#{i}" }
    else
      # Variable number of arguments.
      ((1..(-method_def.arity - 1)).map { |i| "arg#{i}" } << '*args')
    end
    arg_list << '&block' if capture_block
    arg_list.join ', '
  end

  # The list of arguments used to call a proxied method.
  #
  # This assumes that the proxy method definition uses the code retuned by
  # proxy_argument_list.
  #
  # @param [Method] method_def the definition of the method to be proxied;
  #     should match the value passed to proxy_argument_list
  # @return [String] a chunk of Ruby that can be used as the argument list when
  #     defining a proxy for the given method
  def self.proxy_call_argument_list(method_def)
    source = Police::VmInfo.method_source method_def
    if source == :native || source == :kernel
      proxy_low_level_call_argument_list method_def
    else
      proxy_argument_list method_def, false
    end
  end

  # The list of arguments used to call a proxied low-level method.
  #
  # Low-level methods don't use Ruby methods to manipulate their arguments, so
  # they can't work on proxies, and need to receive the proxied objects
  # as arguments.
  #
  # @param [Method] method_def the definition of the method to be proxied;
  #     should match the value passed to {#proxy_argument_list}
  # @return [String] a chunk of Ruby that can be used as the argument list when
  #     defining a proxy for the given method
  def self.proxy_low_level_call_argument_list(method_def)
    arg_list = if method_def.arity >= 0
      # Fixed number of arguments.
      (1..method_def.arity).map do |i|
        "(nil == arg#{i}.__police_labels__) ? arg#{i} : " +
            "arg#{i}.__police_proxied__"
      end
    else
      # Variable number of arguments.
      args_mapper =  '*(args.map { |a| (nil == a.__police_labels__) ? a : ' +
          'a.__police_proxied__ })'
      (1..(-method_def.arity - 1)).map { |i|
        "(nil == arg#{i}.__police_labels__) ? arg#{i} : " +
            "arg#{i}.__police_proxied__"
      } << args_mapper
    end
    arg_list.join ', '
  end

  # Boolean expression deciding if a proxied method received labeled arguments.
  #
  # If none of the method's arguments is labeled, the sticky label propagation
  # logic can be completely bypassed.
  #
  # @param [Method] method_def the definition of the method to be proxied;
  #   should match the value passed to {#proxy_argument_list}
  # @return [String] a chunk of Ruby that sets the 'fast_sticky' local variable
  #   to a truthy value if none of the proxied method's arguments is labeled,
  #   and to a falsey value if at least one argument has a label
  def self.proxy_sticky_fastpath_check(method_def)
    # Don't generate anything for zero-argument methods.
    return '' if method_def.arity == 0

    boolean_list = if method_def.arity > 0
      # Fixed number of arguments.
      (1..method_def.arity).map do |i|
        "(nil == arg#{i}.__police_stickies__)"
      end
    else
      # Variable number of arguments.
      args_boolean = '(args.all? { |a| nil == a.__police_stickies__ })'
      (1..(-method_def.arity - 1)).map { |i|
        "(nil == arg#{i}.__police_stickies__)"
      } << args_boolean
    end
    'fast_sticky = ' + boolean_list.join(' && ')
  end

  # Code for computing the union of the arguments' sticky labels.
  #
  # The code is wrapped in a check that assumes the code returned by
  # {#proxy_sticky_fastpath_check} was already executed.
  #
  # @param [Method] method_def the definition of the method to be proxied;
  #   should match the value passed to {#proxy_argument_list} and
  #   {#proxy_sticky_fastpath_check}
  # @return [String] a chunk of Ruby that sets the 'sticky_labels' local
  #   variable to a label set that contains all the sticky labels in the
  #   method's arguments
  def self.proxy_sticky_gathering(method_def)
    # Don't generate anything for zero-argument methods.
    return '' if method_def.arity == 0

    code_lines = ['unless fast_sticky', 'sticky_labels = {}']
    if method_def.arity > 0
      # Fixed number of arguments.
      1.upto method_def.arity do |i|
        code_lines << "unless nil == arg#{i}.__police_stickies__"
        code_lines <<   '::Police::DataFlow::Labeling.merge_sets!(' +
                            "sticky_labels, arg#{i}.__police_stickies__)"
        code_lines << 'end'
      end
    else
      # Variable number of arguments.
      1.upto(-method_def.arity - 1) do |i|
        code_lines << "unless nil == arg#{i}.__police_stickies__"
        code_lines <<   '::Police::DataFlow::Labeling.merge_sets!(' +
                            "sticky_labels, arg#{i}.__police_stickies__)"
        code_lines << 'end'
      end
      code_lines << 'args.each do |a|'
      code_lines <<   'unless nil == a.__police_stickies__'
      code_lines <<     '::Police::DataFlow::Labeling.merge_sets!(' +
                            'sticky_labels, a.__police_stickies__)'
      code_lines <<   'end'
      code_lines << 'end'
    end
    code_lines << 'end'
    code_lines.join '; '
  end

  # Code for applying argument sticky labels to a method's yielded arguments.
  #
  # This code assumes that the code returned by {#proxy_sticky_fastpath_check}
  # and {#proxy_sticky_gathering} was already executed.
  #
  # @param [Method] method_def the definition of the method to be proxied;
  #   should match the value passed to {#proxy_argument_list} and
  #   {#proxy_sticky_fastpath_check}
  # @return [String] a chunk of Ruby that sets the 'sticky_labels' local
  #   variable to a label set that contains all the sticky labels in the
  #   method's arguments
  def self.proxy_yield_sticky_decorating(method_def)
    # Don't generate anything for zero-argument methods.
    return '' if method_def.arity == 0

    'unless fast_sticky; ' +
      'yield_args.map! do |a|; ' +
        '::Police::DataFlow::Labeling.bulk_sticky_label(a, sticky_labels); ' +
      'end; ' +
    'end'
  end

  def self.proxy_return_sticky_decorating(method_def)
    # Don't generate anything for zero-argument methods.
    return '' if method_def.arity == 0

    'unless fast_sticky; ' +
      'return_value = ::Police::DataFlow::Labeling.bulk_sticky_label(' +
          'return_value, sticky_labels); ' +
    'end'
  end
end  # namespace Police::DataFlow::Proxying

end  # namespace Police::DataFlow

end  # namespace Police
