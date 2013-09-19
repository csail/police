# Label that tests the noop proxying implementation.
class NoFlowFixture < Police::DataFlow::Label
  def self.autoflow?(method_name)
    false
  end

  def self.return_hook(method_name)
    nil
  end

  def self.yield_args_hook(filter_name)
    nil
  end
end  # class NoFlowFixture
