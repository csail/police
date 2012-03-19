module Police
  
module Labels

# Marks strings that are read from the outside environment with no sanitization.
class UnsafeString < Police::DataFlow::Label
  # @see Police::DataFlow::Label#autoflow?
  def autoflow?
    true
  end
  
  # @see Police::DataFlow::Label#accept?
  def accept?(data)
    data.kind_of? String
  end
  
  # @see Police::DataFlow::Label#call_hook_name
  def call_hook_name(method_name, klass)
    nil
  end
  
end  # namepsace Police::Labels::UnsafeString
  
end  # namespace Labels

end  # namespace Police
