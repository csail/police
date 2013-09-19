module Police

module DataFlow

# Superclass for objects used as data flow labels.
class Label
  # True for labels that automatically propagate across operations.
  #
  # This method's return value is used for methods where the label does not
  # provide a hook. Hooks are responsible for label propagation.
  #
  # Labels that indicate privacy should auto-flow in most cases. For example,
  # an auto-generated message that contains a user's phone number is just as
  # sensitive as the phone number.
  #
  # Labels that indicate sanitization should not auto-flow by default. For
  # example, a substring of an HTML-sanitized string is not necessarily
  # HTML-sanitized.
  #
  # @param [Symbol] method_name the name of the method for which the label
  #     should autoflow;
  # @return [Boolean] if true, the label will be automatically added to objects
  #     whose value is likely to be derived from other labeled objects; the
  #     return value for a given method name should always be the same
  def self.autoflow?(method_name)
    true
  end

  # Label method changing the return value of a method in a labeled object.
  #
  # @param [Symbol] method_name the name of the method that will be decorated
  #     by the label
  # @return [Symbol, NilClass] the name of a label instance method that will
  #     be given a chance to label the decorated method's return value; the
  #     return value for a given method name should always be the same
  #
  # @see Police::DataFlow::Label.sample_return_hook
  def self.return_hook(method_name)
    :sample_return_hook
  end

  # Label method changing the values yielded by a method in a labeled object.
  #
  # @param [Symbol] method_name the name of the method that will be decorated
  #     by the label
  # @return [Symbol, NilClass] the name of a label instance method that will
  #     be given a chance to label the values yielded by the decorated method
  #     to its block
  #
  # @see Police::DataFlow::Label.sample_yield_args_hook
  def self.yield_args_hook(method_name)
    :sample_yield_args_hook
  end

  # Hook that can label a decorated method's return value.
  #
  # @param [Object] value the decorated method's return value; if a method is
  #     decorated by multiple labels, the value might be already labeled by
  #     another label's return hook
  # @param [Object] receiver the object that the decorated method was called on
  # @param [Array] args the arguments passed to the decorated method
  # @return [Object] either the un-modified value argument, or the return value
  #     of calling {Police::DataFlow.label} on the value argument
  def sample_return_hook(value, receiver, *args)
    Police::DataFlow.label value, self
  end

  # Hook that can label the values that a decorated method yields to its block.
  #
  # @param [Object] receiver the object that the decorated method was called on
  # @param [Array] yield_args the arguments yielded by the decorated method to
  #     its block; the array's elements can be replaced with the return values
  #     of calling {Police::DataFlow.label} on them; if a method is
  #     decorated by multiple labels, the values might be already labeled by
  #     another label's yield values hook
  # @param [Array] args the arguments passed to the decorated method
  def sample_yield_args_hook(receiver, yield_args, *args)
    yield_args.map! { |arg| Police::DataFlow.label arg, self }
  end

  # An opportunity for a label to reject being attached to a piece of data.
  #
  # @param [Object] data the data that this label will be attached to
  # @return [Boolean] true if this label can be used with the given piece of
  #     data; if this method returns false, the labeling code will raise an
  #     exception
  def accepts?(data)
    true
  end
end  # module Police::DataFlow::Label

end  # namespace Police::DataFlow

end  # namespace Police
