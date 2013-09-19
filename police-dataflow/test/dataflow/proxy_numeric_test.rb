require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::ProxyNumeric do
  before do
    Police::DataFlow::Proxies.clear_cache
    @label = AutoFlowFixture.new
    @label_set = {}
    Police::DataFlow::Labeling.add_label_to_set @label, @label_set
    @proxied = 21
    @proxy_class = Police::DataFlow::Proxies.for @proxied.class, @label_set
    @proxy = @proxy_class.new @proxied, @proxy_class, @label_set
  end
  after { Police::DataFlow::Proxies.clear_cache }

  it 'defines coerce' do
    @proxy_class.instance_methods.must_include :coerce
  end

  it 'returns a two-element Array from coerce' do
    coerced = @proxy.coerce 42
    coerced.class.must_equal Array
    coerced.length.must_equal 2
  end

  it 'proxies the argument when coercing' do
    coerced = @proxy.coerce 42
    coerced[0].must_equal 42
    coerced[0].__id__.wont_equal 42.__id__
  end

  it 'returns self correctly when coercing' do
    coerced = @proxy.coerce 42
    coerced[1].__id__.must_equal @proxy.__id__
  end

  it 'does not double-proxy' do
    @proxied2 = 22
    @proxy2 = @proxy_class.new @proxied2, @proxy_class, @label_set
    coerced = @proxy.coerce @proxy2
    coerced[0].__id__.must_equal @proxy2.__id__
    coerced[1].__id__.must_equal @proxy.__id__
    coerced.class.must_equal Array
    coerced.length.must_equal 2
  end
end
