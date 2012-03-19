module Police
  
module Labels

# Adds a label to any data read from a IO stream.
class UnsafeStream < Police::DataFlow::Label
  # @param [Police::DataFlow::Label] unsafe_label the label that will be added
  #     to the stream's data
  def initialize(unsafe_label)
    @label = unsafe_label
  end
  
  # @see Police::DataFlow::Label#autoflow?
  def autoflow?
    false
  end
  
  # @see Police::DataFlow::Label#accepts?
  def accepts?(data)
    data.kind_of?(IO) || data.kind_of?(StringIO)
  end
  
  # @see Police::DataFlow::Label#call_hook_name
  def call_hook_name(method_name, klass)
    case method_name
    when :read
      :read
    else
      nil
    end
  end
  
  # Adds a label to the read's return value.
  # @see IO#read
  def read(return_value, receiver, *args)
    Police::DataFlow.label return_value, @label
  end
end  # namepsace Police::Labels::UnsafeStream
  
end  # namespace Labels

end  # namespace Police
