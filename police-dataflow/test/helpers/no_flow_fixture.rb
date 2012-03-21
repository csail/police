# Label that tests the no-autoflow behavior. 
class NoFlowFixture < Police::DataFlow::Label
  def self.autoflow?
    false
  end
  
  def self.return_filter(method_name)
    nil
  end
  
  def self.yield_args_filter(filter_name)
    nil
  end
end  # class NoFlowFixture
