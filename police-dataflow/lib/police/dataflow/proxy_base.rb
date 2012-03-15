module Police

module DataFlow

# Base class for labeled objects replacements.
class ProxyBase < BasicObject
  # The object being proxied by this object.
  #
  # @private
  # Use the Police::DataFlow API instead of reading this attribute directly.
  attr_reader :__police_proxied__
  
  # The Label instances attached to the proxied object.
  #
  # @private
  # Use the Police::DataFlow API instead of reading this attribute directly.
  attr_reader :__police_labels__
  
  # Creates a proxied object.
  def initialize(proxied)
    @__police_proxied__ = proxied
    @__police_labels__ = {}
    # TODO(pwnall): locks for multi-threading
  end

  # Handles method calls to the proxied object.
  #
  # Whenever possible, proxy methods are created on-the-fly, so that future
  # calls to the same method will be faster.
  def method_missing(name, *args, &block)
    if respond_to_missing?(name, true)
      # The proxy method was defined in respond_to_missing.
      # We'll have a fast path for future method calls.
      __send__ name, *args, &block
    else
      # Slow proxy path.
      # TODO(pwnall): labeling
      @__police_proxied__.__send__ name, *args, &block
    end
  end
  
  # Called when Object#respond_to? returns false.
  def respond_to_missing?(name, include_private)
    return false unless @__police_proxied__.respond_to? name, include_private    
    
    # A method on the proxied object doesn't have a corresponding proxy.
    # Fix this by creating all possible proxies.
    
    # NOTE: this approach is cheaper than creating proxies one by one, because
    #       it plays nice with method caches
    
    ::Police::DataFlow::Proxying.add_class_methods self.class,
                                                   @__police_proxied.class
    
    # NOTE: we don't want to create unnecessary singleton classes
    target_methods = @__police_proxied__.singleton_methods true
    self_methods = self.singleton_methods
    if target_methods.length != self_methods.length
      ::Police::DataFlow::Proxying.add_singleton_methods self,
          @__police_proxied__, target_methods
    end
  end
end

end  # namespace Police::DataFlow

end  # namespace Police
