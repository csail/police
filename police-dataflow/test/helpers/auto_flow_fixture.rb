# Label that tests the autoflow behavior.
class AutoFlowFixture < Police::DataFlow::Label
  def self.autoflow?(method_name)
    true
  end
end  # class AutoFlowFixture
