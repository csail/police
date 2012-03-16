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
  
  # Opportunity to "taint" the result of an operation on labeled data.
  #
  # @param [Object] result the result of the method call
  # @param [Object] receiver the method's receiver
  # @param [Symbol] method the name of the method that was called
  # @param [Array] arguments the arguments passed to the method
  # @param [Object] labeled the object labeled by this label that triggered the
  #     flow_to call; this is either the receiver, or one of the arguments
  # @return [Object] result, or the return value of calling
  #     Police::Dataflow.label on the result
  def flow_to(result, receiver, method, arguments, labeled)
    Police::DataFlow::Labeler.label result, self
  end
  
  # Indicates messages that are not subject to labeling.
  #
  # @param [Symbol] method the name of the method that the caller is trying to
  #    optimize 
  # @return [Boolean] true if the result of calling this method on labeled
  #     data never needs to be labeled; for example, methods that return the
  #     receiver should not be subject to labeling
  def flows_on?(method)
    true
  end
end  # module Police::DataFlow::Label

end  # namespace Police::DataFlow

end  # namespace Police
