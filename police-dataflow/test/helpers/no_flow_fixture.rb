# Label that tests the no-autoflow behavior. 
class NoFlowFixture < Police::DataFlow::Label
  def self.autoflow?
    false
  end
end  # class NoFlowFixture
