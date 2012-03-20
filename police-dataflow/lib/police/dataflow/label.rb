module Police

module DataFlow

# Superclass for objects used as data flow labels.
class Label
  # True for labels that automatically propagate across operations.
  #
  # Labels that indicate privacy auto-flow. For example, an auto-generated
  # message that contains a user's phone number is just as sensitive as the
  # phone number.
  # 
  # Labels that indicate sanitization do not auto-flow. For example, a substring
  # of an HTML-sanitized string is not necessarily HTML-sanitized.
  #
  # @return [Boolean] if true, the label will be automatically added to objects
  #     whose value is likely to be derived from other labeled objects
  def self.autoflow?
    true
  end
  
  # Label method that filters a proxied method's return value.
  #
  # @param [Symbol] method_name the name of the method that will be intercepted
  #     by the label method.
  # @return [Symbol, NilClass] the name of the label's instance method that will
  #     be given a chance to inspect the proxied method's return value and
  #     change it
  def self.return_filter(method_name)
    :sample_return_filter
  end
  
  # Label method that filters a proxied method's yielded values.
  #
  # @param [Symbol] method_name the name of the method that will be intercepted
  #     by the label method.
  # @return [Symbol, NilClass] the name of the label's instance method that will
  #     be given a chance to inspect the proxied method's return value and
  #     change it
  def self.yield_args_filter(method_name)
    :sample_yield_args_filter
  end
  
  # Filter for a method's return value.
  #
  # @param [Object] value the method's original return value; if a method's
  #     return is filtered by multiple labels, this might be the output of
  #     another label's return value filter
  # @param [Object] receiver the method's receiver
  # @param [Array] args the arguments passed to the method
  # @return [Object] result, or the return value of calling
  #     Police::Dataflow.label on the result
  def sample_return_filter(value, receiver, *args)
    Police::DataFlow.label value, self
  end

  # Filter for the values that a method yields to its block.
  #
  # @param [Object] value the method's original return value; if a method's
  #     return is filtered by multiple labels, this might be the output of
  #     another label's return value filter
  # @param [Object] receiver the method's receiver
  # @param [Array] yield_args the arguments yielded by the method to its block;
  #     the array's content should be modified in-place; for example, elements
  #     can be replaced with Police::DataFlow.label versions if desired
  # @param [Array] args the arguments passed to the method
  def sample_yield_args_filter(receiver, yield_args, *args)
    yield_args.map! { |arg| Police::DataFlow.label value, arg }
  end

  # An opportunity for a label to reject being used on a piece of data.
  #
  # @param [Object] data the data that will receive this label
  # @return [Boolean] true if this label can be used with the given piece of
  #     data; if this method returns false, the labeling code will raise an
  #     exception
  def accepts?(data)
    true
  end
end  # module Police::DataFlow::Label

end  # namespace Police::DataFlow

end  # namespace Police
