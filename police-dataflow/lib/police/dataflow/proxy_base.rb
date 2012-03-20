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
  
  # The subset of this object's labels whose autoflow? method returns true.
  #
  # @private
  # This is an optimization used by the Police::DataFlow implementation. Do not
  # read it directly.
  attr_reader :__police_autoflowing__
  
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
    @__police_autoflowing__ = {}
  end

  # Handles method calls to the proxied object.
  #
  # Whenever possible, proxy methods are created on-the-fly, so that future
  # calls to the same method will be faster.
  def method_missing(name, *args, &block)
    # Build a fast path for future method calls, if possible.
    respond_to_missing? name, true

    if block
      return_value = @__police_proxied__.__send__ name, *args do |*block_args|
        # Yielded values filtering.
        @__police_labels__.each do |_, labels|
          next unless filter_name = labels.first.class.yield_args_filter(name)
          labels.each do |label|
            block_args = label.__send__ hook_name, self, *args, block_args
          end
        end
        
        block_return = yield(*block_args)
        # TODO(pwnall): consider adding a yield value filter
        next block_return
      end
    else
      return_value = @__police_proxied__.__send__ name, *args, &block
    end
    
    # Return value filtering.
    @__police_labels__.each do |_, labels|
      next unless filter_name = labels.first.class.return_filter(name)
      labels.each do |label|
        return_value = label.__send__ filter_name, return_value, self, *args
      end
    end
    return return_value
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
  
  # Remove the == and != implementations from BasicObject, so that we can proxy
  # them. This is particularly important for String.
  #
  # NOTE: We don't remove equal?, because Object's documentation says that
  #       BasicObject subclasses should really not override it. We also don't
  #       remove instance_eval and instance_exec, so the code that gets executed
  #       using them will still have its method calls proxied correctly.
  undef ==, !=

  class <<self
    # The classes of the labels supported by the proxy class.
    #
    # @private
    # This is a Police::DataFlow implementation detail. Do not read it directly.
    attr_accessor :__police_classes__
  end  
end  # class Police::DataFlow::ProxyBase

end  # namespace Police::DataFlow

end  # namespace Police
