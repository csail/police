module Police

module DataFlow

# Interface implemented by objects used as data flow labels.
module Label
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
