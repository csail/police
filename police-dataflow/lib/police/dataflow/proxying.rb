module Police

module DataFlow

# The complex method dispatching logic used by ProxyBase.
#
# ProxyBase is the superclass for all proxy classes, which makes it visible to
# application code. For this reason, we avoid defining any methods there.
module Proxying
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
  end

  # Adds a method to a proxy class.
  #
  # @param [Module] proxy_class the class that will receive the proxy method
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  def self.add_class_method(proxy_class, method_def, access)
    # Avoid redefining methods, because that blows up VM caches.
    return if proxy_class.method_defined?(method_def.name)
    
    # Define the method.
    proxy_class.class_eval proxy_method_definition(method_def, access)
    # Set its access level.
    proxy_class.__send__ access, method_def.name
  end
  
  # The full definition of a proxy method.
  #
  # @param [Method] method_def the definition of the method to be proxied
  # @param [Symbol] access the proxied method's access level (:public,
  #     :protected, or :private)
  # @return [String] a chunk of Ruby that can be eval'ed in the context of a
  #     proxy class to define a proxy for the given method
  def self.proxy_method_definition(method_def, access)
    # NOTE: it might be tempting to attempt to pass a block to the proxied
    #       method at all times, and try to yield to the original block when our
    #       block is invoked; this would work most of the time, but it would
    #       break methods such as Enumerable#map and String#scan, whose behavior
    #       changes depending on whether or not a block is passed to them
    ["def #{method_def.name}(#{proxy_argument_list(method_def, true)})",
       "if block",
         proxy_method_call(method_def, access, false) + " do |*block_args|",
           # TODO(pwnall): labeling
           "yield(*block_args)",
           # TODO(pwnall): labeling
         "end",
       "else",
         proxy_method_call(method_def, access, false),
         # TODO(pwnall): labeling
       "end",
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
