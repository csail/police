# Label that tests the no-autoflow behavior. 
class NoFlowFixture < Police::DataFlow::Label
  def autoflow?
    true
  end
end  # class NoFlowFixture
