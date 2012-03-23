module Police
  
module Labels

# Marks strings that are read from the outside environment with no sanitization.
class UnsafeString < Police::DataFlow::Label
  # @see Police::DataFlow::Label#autoflow?
  def self.autoflow?
    true
  end
  
  # @see Police::DataFlow::Label#accept?
  def accept?(data)
    data.kind_of? String
  end
  
  # @see Police::DataFlow::Label#return_hook
  def self.return_hook(method_name)
    nil
  end
  
  # @see Police::DataFlow::Label#yield_args_hook
  def self.yield_args_hook(method_name)
    nil
  end
end  # namepsace Police::Labels::UnsafeString
  
end  # namespace Labels

end  # namespace Police
