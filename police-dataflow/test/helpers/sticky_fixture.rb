# Label that tests autoflow proxying implementation.
class StickyFixture < Police::DataFlow::Label
  def self.sticky?
    true
  end

  def self.return_hook(method_name)
    nil
  end

  def self.yield_args_hook(method_name)
    nil
  end
end  # class StickyFixture
