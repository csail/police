# Label that tests the no-autoflow behavior.
class HooksFlowFixture < Police::DataFlow::Label
  def self.autoflow?(method_name)
    false
  end

  def self.return_hook(method_name)
    :sample_return_hook
  end

  def self.yield_args_hook(filter_name)
    :sample_yield_hook
  end
end  # class HooksFlowFixture
