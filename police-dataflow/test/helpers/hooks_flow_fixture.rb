# Label that tests the hook-based proxying implementation.
class HooksFlowFixture < Police::DataFlow::Label
  def self.autoflow?(method_name)
    false
  end

  def self.return_hook(method_name)
    :generic_return_hook
  end

  def self.yield_args_hook(method_name)
    :generic_yield_args_hook
  end

  def generic_return_hook(value, receiver, *args)
    Police::DataFlow.label value, self
  end

  def generic_yield_args_hook(receiver, yield_args, *args)
    yield_args.map! { |arg| Police::DataFlow.label arg, self }
  end
end  # class HooksFlowFixture
