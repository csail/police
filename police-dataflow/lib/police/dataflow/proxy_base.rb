module Police

module DataFlow

# Base class for labeled objects replacements.
class ProxyBase < BasicObject
  # The object being proxied by this object.
  #
  # @private
  # Use the {Police::DataFlow} API instead of reading this attribute directly.
  attr_reader :__police_proxied__

  # The {Police::DataFlow::Label} instances attached to the proxied object.
  #
  # @private
  # Use the {Police::DataFlow} API instead of reading this attribute directly.
  attr_reader :__police_labels__

  # The actual class of a proxy object.
  #
  # This is necessary because the class method for a proxy object must return
  # the proxied object's class.
  #
  # @private
  # Use the {Police::DataFlow} API instead of reading this attribute directly.
  attr_reader :__police_class__

  # Creates a proxied object.
  #
  # @param [Object] proxied the object that will receive messages sent to the
  #     newly created proxy
  # @param [Class<Police::DataFlow::ProxyBase>] proxy_class the
  #     {Police::DataFlow::ProxyBase} subclass being instantiated; Object
  #     instances can call Object#class to get to their class, but BasicObject
  #     instances don't have this luxury
  # @param [Hash<Integer,Hash<Police::DataFlow::Label,Boolean>>] label_set the
  #     set of all labels that will be held by the object's proxy
  def initialize(proxied, proxy_class, label_set)
    @__police_proxied__ = proxied
    @__police_labels__ = label_set

    # Holds the object's class, because Object#class is not available.
    @__police_class__ = proxy_class
  end

  # Handles method calls to the proxied object.
  #
  # Whenever possible, proxy methods are created on-the-fly, so that future
  # calls to the same method will be faster.
  def method_missing(name, *args, &block)
    # Build a fast path for future method calls, if possible.
    respond_to_missing? name, true

    # NOTE: going out of our way to use the fast path methods, because they
    #       handle native method argument unwrapping correctly
    if @__police_class__.method_defined?(name) ||
        @__police_class__.private_method_defined?(name)
      return __send__(name, *args, &block)
    end

    if block
      return_value = @__police_proxied__.__send__ name, *args do |*yield_args|
        # Yielded values filtering.
        @__police_labels__.each do |_, label_hash|
          label_class = label_hash.first.first.class
          if hook = label_class.yield_args_hook(name)
            label_hash.each do |label, _|
              yield_args = label.__send__ hook, self, yield_args, *args
            end
          elsif label_class.autoflow?(name)
            label_hash.each do |label, _|
              yield_args.map! { |arg| ::Police::DataFlow.label arg, label }
            end
          end
        end

        yield_return = yield(*yield_args)
        # TODO(pwnall): consider adding a yield value filter
        next yield_return
      end
    else
      return_value = @__police_proxied__.__send__ name, *args
    end

    # Return value filtering.
    @__police_labels__.each do |_, label_hash|
      label_class = label_hash.first.first.class
      if hook = label_hash.first.first.class.return_hook(name)
        label_hash.each do |label, _|
          return_value = label.__send__ hook, return_value, self, *args
        end
      elsif label_class.autoflow?(name)
        label_hash.each do |label, _|
          return_value = ::Police::DataFlow.label return_value, label
        end
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

    ::Police::DataFlow::Proxying.add_instance_methods @__police_class__,
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
  #       remove instance_eval and instance_exec, so the code that gets
  #       executed using them will still have its method calls proxied
  #       correctly.
  undef ==, !=

  class <<self
    # The classes of the labels supported by the proxy class.
    #
    # @private
    # This is a Police::DataFlow implementation detail. Do not read it
    # directly.
    attr_accessor :__police_classes__
  end
end  # class Police::DataFlow::ProxyBase

end  # namespace Police::DataFlow

end  # namespace Police
