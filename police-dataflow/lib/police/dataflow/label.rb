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
  def autoflow?
    true
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

  # The name of the label's method
  #
  # @param [Symbol] method_name the name of the method that will be intercepted
  #     by the label method.
  # @return [Symbol, NilClass] the name of the label's instance method that will
  #     be called after the intercepted method
  def call_hook_name(method_name, klass)
    true
  end
  
  
  # Opportunity to "taint" the result of an operation on labeled data.
  #
  # @param [Object] result the result of the method call
  # @param [Object] receiver the method's receiver
  # @param [Symbol] method_name the name of the method that was called
  # @param [Array] args the arguments passed to the method
  # @return [Object] result, or the return value of calling
  #     Police::Dataflow.label on the result
  def hook(result, receiver, method_name, *args)
    Police::DataFlow::Labeler.label result, self
  end
end  # module Police::DataFlow::Label

end  # namespace Police::DataFlow

end  # namespace Police
