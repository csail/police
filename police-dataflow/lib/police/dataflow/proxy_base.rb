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
  #
  # @param [Object] proxied the object that will receive messages sent to the
  #     newly created proxy
  # @param [Class<Police::DataFlow::ProxyBase>] proxy_class the
  #     Police::DataFlow::ProxyBase subclass being instantiated; Object
  #     instances can call Object#class to get to their class, but BasicObject
  #     instances don't have this luxury
  def initialize(proxied, proxy_class)
    @__police_proxied__ = proxied
    @__police_labels__ = {}

    # Holds the object's class, because Object#class is not available.
    @__police_class__ = proxy_class

    # Labels that flow automatically across method calls.
    @__police_autoflow_labels__ = {}
  end

  # Handles method calls to the proxied object.
  #
  # Whenever possible, proxy methods are created on-the-fly, so that future
  # calls to the same method will be faster.
  def method_missing(name, *args, &block)
    # Build a fast path for future method calls, if possible.
    respond_to_missing? name, true

    if block
      @__police_proxied__.__send__ name, *args do |*block_args|
        # TODO(pwnall): labeling
        block_return = yield *block_args
        # TODO(pwnall): labeling
        next block_return
      end
    else
      @__police_proxied__.__send__ name, *args, &block
      # TODO(pwnall): labeling
    end
  end
  
  # Called when Object#respond_to? returns false.
  def respond_to_missing?(name, include_private)
    return false unless @__police_proxied__.respond_to? name, include_private
    
    # A method on the proxied object doesn't have a corresponding proxy.
    # Fix this by creating all possible proxies.
    
    # NOTE: this approach is cheaper than creating proxies one by one, because
    #       it plays nice with method caches
    
    ::Police::DataFlow::Proxying.add_class_methods @__police_class__,
                                                   @__police_proxied__.class
    
    # NOTE: we don't want to create unnecessary singleton classes
    # target_methods = @__police_proxied__.singleton_methods true
    # unless target_methods.empty?
    #  ::Police::DataFlow::Proxying.add_singleton_methods self,
    #      @__police_proxied__, target_methods
    # end
    
    true
  end
  
  # Ruby 1.9 throws scary warnings if proxies define object_id.
  # In either case, it's probably best to have it match __id__.
  alias object_id __id__
end

end  # namespace Police::DataFlow

end  # namespace Police
