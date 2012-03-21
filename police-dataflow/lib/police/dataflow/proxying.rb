module Police

module DataFlow

# The complex method dispatching logic used by ProxyBase.
#
# ProxyBase is the superclass for all proxy classes, which makes it visible to
# application code. For this reason, we avoid defining any methods there.
module Proxying
  # Creates a label-holding proxy for an object.
  #
  # @param [Object] proxied the object to be proxied
  # @param [Array<Integer>] label_keys 
  # @return [Police::DataFlow::ProxyBase] an object that can carry labels, and
  #     performs label-propagation as it redirects received messages to the
  #     proxied object
  def self.proxy(proxied, label_set, autoflow_set)
    proxy_class = Police::DataFlow::Proxies.for proxied.class, label_set
    proxy_class.new proxied, proxy_class, label_set, autoflow_set
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
  def self.add_class_methods(proxy_class, klass)
    # NOTE: this is thread-safe because, at worst, the effort of adding methods
    #       will be re-duplicated
    klass.public_instance_methods(true).each do |method|
      add_class_method proxy_class, klass.instance_method(method), :public
    end
    klass.protected_instance_methods(true).each do |method|
      add_class_method proxy_class, klass.instance_method(method), :protected
    end
    klass.private_instance_methods(true).each do |method|
      add_class_method proxy_class, klass.instance_method(method), :private
    end
    nil
  end

  # Adds a method to a proxy class.
  #
  # @param [Module] proxy_class the class that will receive the proxy method
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  def self.add_class_method(proxy_class, method_def, access)
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
    #       method at all times, and try to yield to the original block when our
    #       block is invoked; this would work most of the time, but it would
    #       break methods such as Enumerable#map and String#scan, whose behavior
    #       changes depending on whether or not a block is passed to them
    ["def #{method_def.name}(#{proxy_argument_list(method_def, true)})",
       "return_value = if block",
         proxy_method_call(method_def, access, false) + " do |*yield_args|",
           proxy_yield_args_filter(label_classes, method_def),
           "block_return = yield(*yield_args)",
           # TODO(pwnall): consider adding a yield value filter
           "next block_return",
         "end",
       "else",
         proxy_method_call(method_def, access, false),
       "end",
        proxy_return_filter(label_classes, method_def),
       "return return_value",
     "end"].join ';'
  end
  
  # The proxying call to a method.
  #
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  # @param [Boolean] include_block if true, the method call passes the block
  #     that the proxy has received; if false, the block is ignored
  # @return [String] a chunk of Ruby that can be used to call the given method
  #     when defining a proxy for it
  def self.proxy_method_call(method_def, access, include_block)
    arg_list = proxy_argument_list method_def, include_block

    if access == :public
      "@__police_proxied__.#{method_def.name}(#{arg_list})"
    else
      "@__police_proxied__.__send__(:#{method_def.name}, #{arg_list})"
    end
  end
  
  # The filtering of the values that a method yields to its block.
  #
  # @param [Array<Police::DataFlow::Label>] label_classes the label classes
  #     supported by the proxy class
  # @param [Method] method_def the definition of the method to be proxied
  # @return [String] a chunk of Ruby that can be used to invoke the yield args
  #     filters of the labels held by a proxy
  def self.proxy_yield_args_filter(label_classes, method_def)
    method_name = method_def.name
    arg_list = proxy_argument_list method_def, false
    code_lines = ['labels = @__police_labels__']
    label_classes.each do |label_class|
      next unless filter_name = label_class.yield_args_filter(method_name)
      label_key = label_class.__id__
      code_lines << "labels[#{label_key}].each { |label, _| " \
          "label.#{filter_name}(self, yield_args, #{arg_list}) }"
    end
    (code_lines.length > 1) ? code_lines.join('; ') : ''
  end
  
  # The filtering of a method's return value.
  #
  # @param [Array<Police::DataFlow::Label>] label_classes the label classes
  #     supported by the proxy class
  # @param [Method] method_def the definition of the method to be proxied
  # @return [String] a chunk of Ruby that can be used to invoke the return value
  #     filters of the labels held by a proxy
  def self.proxy_return_filter(label_classes, method_def)
    method_name = method_def.name
    arg_list = proxy_argument_list method_def, false
    code_lines = ['labels = @__police_labels__']
    label_classes.each do |label_class|
      next unless filter_name = label_class.return_filter(method_name)
      label_key = label_class.__id__
      code_lines << "labels[#{label_key}].each { |label, _| " \
          "return_value = label.#{filter_name}(return_value, self, " \
          "#{arg_list}) }"
    end
    (code_lines.length > 1) ? code_lines.join('; ') : ''
  end
  
  # The list of arguments used to define a proxy for the given method.
  #
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Boolean] captue_block if true, the method captures the block that it
  #     receives
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
end  # namespace Police::DataFlow::Proxying

end  # namespace Police::DataFlow

end  # namespace Police
