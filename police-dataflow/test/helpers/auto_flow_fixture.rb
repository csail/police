# Label that tests the autoflow proxying implementation.
class AutoFlowFixture < Police::DataFlow::Label
  def self.autoflow?(method_name)
    true
  end

  def self.return_hook(method_name)
    nil
  end

  def self.yield_args_hook(method_name)
    nil
  end
end  # class AutoFlowFixture
