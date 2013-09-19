require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::ProxyBase do
  before do
    Police::DataFlow::Proxies.clear_cache

    @label = AutoFlowFixture.new
    @label_set = {}
    Police::DataFlow::Labeling.add_label_to_set @label, @label_set
    @proxied = ProxyingFixture.new
    @proxy_class = ::Police::DataFlow::Proxies.for ProxyingFixture, @label_set
    @proxy = @proxy_class.new @proxied, @proxy_class, @label_set
  end
  after { Police::DataFlow::Proxies.clear_cache }

  it 'proxies public methods' do
    # NOTE: this test exercises the define-and-call path in method_missing
    @proxy.route('One', 'Two').must_equal ['One', 'Two']
  end

  it 'proxies method_missing methods' do
    @proxy.magic_
  end

  it 'allows labels to filter the return value of public methods' do
    # NOTE: this test exercises the re-call path in method_missing
    Police::DataFlow.labels(@proxy.route('One', 'Two')).must_equal [@label]
  end

  describe 'after proxying public methods' do
    before { @proxy.route 'One', 'Two' }

    it 'defines proxied methods on the fly' do
      @proxy_class.public_method_defined?(:route).must_equal true
      @proxy_class.instance_method(:route).owner.must_equal @proxy_class
    end

    it 'still proxies public methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @proxy.route('One', 'Two').must_equal ['One', 'Two']
    end

    it 'still allows labels to filter the return value of public methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      Police::DataFlow.labels(@proxy.route('One', 'Two')).must_equal [@label]
    end

    it 'can still build proxies' do
      other_proxy = @proxy_class.new ProxyingFixture.new, @proxy_class,
          @label_set
      other_proxy.route('One', 'Two').must_equal ['One', 'Two']
    end
  end

  it 'proxies public methods with blocks' do
    # NOTE: this test exercises the slow path in method_missing
    result = []
    @proxy.route('One', 'Two') { |*args| result << args }
    result.must_equal [['One', 'Two']]
  end

  it 'allows labels to filter the yielded values of public methods' do
    # NOTE: this test exercises the slow path in method_missing
    @proxy.route('One', 'Two') do |*args|
      args.each { |arg| Police::DataFlow.labels(arg).must_equal [@label] }
    end
  end

  describe 'after proxying public methods with blocks' do
    before { @proxy.route('One', 'Two') { |*args| } }

    it 'defines proxied methods on the fly' do
      @proxy_class.public_method_defined?(:route).must_equal true
      @proxy_class.instance_method(:route).owner.must_equal @proxy_class
    end

    it 'still proxies public methods with blocks' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      result = []
      @proxy.route('One', 'Two') { |*args| result << args }
      result.must_equal [['One', 'Two']]
    end

    it 'still allows labels to filter the yielded values of public methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @proxy.route('One', 'Two') do |*args|
        args.each { |arg| Police::DataFlow.labels(arg).must_equal [@label] }
      end
    end
  end

  it 'proxies protected methods' do
    # NOTE: this test exercises the slow path in method_missing
    @proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
  end

  it 'allows labels to filter the return value of protected methods' do
    # NOTE: this test exercises the slow path in method_missing
    Police::DataFlow.labels(@proxy.__send__(:add, 'One', 'Two')).
        must_equal [@label]
  end


  describe 'after proxying protected methods' do
    before { @proxy.__send__ :add, 'One', 'Two' }

    it 'defines proxied methods on the fly' do
      @proxy_class.protected_method_defined?(:add).must_equal true
      @proxy_class.instance_method(:add).owner.must_equal @proxy_class
    end

    it 'still proxies protected methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
    end

    it 'still allows labels to filter the return value of protected methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      Police::DataFlow.labels(@proxy.__send__(:add, 'One', 'Two')).
          must_equal [@label]
    end
  end

  it 'proxies method_missing methods' do
    # NOTE: ths test exercises the method_missing+send slow proxying path.
    @proxy.magic_meth('One', 'Two').must_equal ['meth', 'One', 'Two']
  end

  it 'proxies method_missing methods with blocks' do
    # NOTE: ths test exercises the method_missing+send slow proxying path.
    @proxy.magic_meth('One', 'Two') { |*args|
      args.must_equal ['One', 'Two']
      args
    }.must_equal ['meth', ['One', 'Two']]
  end

  it 'allows labels to filter the return value of method_missing methods' do
    Police::DataFlow.labels(@proxy.magic_meth('One', 'Two')).
                     must_equal [@label]
  end

  describe 'after proxying method_missing methods' do
    before do
      @proxy.magic_meth 'One', 'Two'
    end

    it 'does not define proxied methods' do
      @proxy_class.public_method_defined?(:magic_meth).must_equal false
    end
  end

  it 'proxies ==' do
    (@proxy == nil).must_equal '== proxied'
  end

  it 'proxies !=' do
    (@proxy != nil).must_equal '!= proxied'
  end
end
