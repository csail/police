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
  def self.autoflow?
    false
  end
  
  # @see Police::DataFlow::Label#accepts?
  def accepts?(data)
    data.kind_of?(IO) || data.kind_of?(StringIO)
  end
  
  # @see Police::DataFlow::Label#return_filter
  def self.return_filter(method_name)
    case method_name
    when :read
      :read
    else
      nil
    end
  end
  
  # @see Police::DataFlow::Label#yield_args_filter
  def self.yield_args_filter(method_name)
    nil
  end
  
  # Adds a label to the read's return value.
  # @see IO#read
  def read(return_value, receiver, *args)
    Police::DataFlow.label return_value, @label
  end
end  # namespace Police::Labels::UnsafeStream
  
end  # namespace Labels

end  # namespace Police
