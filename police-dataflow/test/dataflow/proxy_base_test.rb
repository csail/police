require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::ProxyBase do
  before do
    Police::DataFlow::Proxies.clear_cache

    @sticky_label = StickyFixture.new
    @hook_label = HooksFlowFixture.new

    @proxied = ProxyingFixture.new

    @sticky_label_set = {}
    Police::DataFlow::Labeling.add_label_to_set @sticky_label,
                                                @sticky_label_set
    @sticky_proxy_class = ::Police::DataFlow::Proxies.for ProxyingFixture,
                                                          @sticky_label_set
    @sticky_proxy = @sticky_proxy_class.new @proxied, @sticky_proxy_class,
                                            @sticky_label_set

    @hook_label_set = {}
    Police::DataFlow::Labeling.add_label_to_set @hook_label, @hook_label_set
    @hook_proxy_class = ::Police::DataFlow::Proxies.for ProxyingFixture,
                                                        @hook_label_set
    @hook_proxy = @hook_proxy_class.new @proxied, @hook_proxy_class,
                                                  @hook_label_set
  end
  after { Police::DataFlow::Proxies.clear_cache }

  it 'proxies public methods through sticky labels' do
    # NOTE: this test exercises the define-and-call path in method_missing
    @sticky_proxy.route('One', 'Two').must_equal ['One', 'Two']
  end

  it 'proxies public methods through hook labels' do
    # NOTE: this test exercises the define-and-call path in method_missing
    @hook_proxy.route('One', 'Two').must_equal ['One', 'Two']
  end

  it 'allows labels to stick to the return value of public methods' do
    # NOTE: this test exercises the define-and-call path in method_missing
    Police::DataFlow.labels(@sticky_proxy.route('One', 'Two')).must_equal(
        [@sticky_label])
  end

  it 'allows labels to hook into the return value of public methods' do
    # NOTE: this test exercises the define-and-call path in method_missing
    Police::DataFlow.labels(@hook_proxy.route('One', 'Two')).must_equal(
        [@hook_label])
  end

  describe 'after proxying public methods' do
    before do
      @sticky_proxy.route 'One', 'Two'
      @hook_proxy.route 'One', 'Two'
    end

    it 'defines proxied methods on the fly' do
      @sticky_proxy_class.public_method_defined?(:route).must_equal true
      @sticky_proxy_class.instance_method(:route).owner.must_equal(
          @sticky_proxy_class)
      @hook_proxy_class.public_method_defined?(:route).must_equal true
      @hook_proxy_class.instance_method(:route).owner.must_equal(
          @hook_proxy_class)
    end

    it 'still proxies public methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @sticky_proxy.route('One', 'Two').must_equal ['One', 'Two']
      @hook_proxy.route('One', 'Two').must_equal ['One', 'Two']
    end

    it 'still allows labels to stick to the return value of methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      Police::DataFlow.labels(@sticky_proxy.route('One', 'Two')).must_equal(
          [@sticky_label])
    end

    it 'still allows labels to hook into the return value of methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      Police::DataFlow.labels(@hook_proxy.route('One', 'Two')).must_equal(
          [@hook_label])
    end

    it 'can still build proxies' do
      other_sticky_proxy = @sticky_proxy_class.new ProxyingFixture.new,
          @proxy_class, @sticky_label_set
      other_sticky_proxy.route('One', 'Two').must_equal ['One', 'Two']

      other_hook_proxy = @hook_proxy_class.new ProxyingFixture.new,
          @proxy_class, @hook_label_set
      other_hook_proxy.route('One', 'Two').must_equal ['One', 'Two']
    end
  end

  it 'proxies public methods with blocks through sticky labels' do
    # NOTE: this test exercises the slow path in method_missing
    result = []
    @sticky_proxy.route('One', 'Two') { |*args| result << args }
    result.must_equal [['One', 'Two']]
  end

  it 'proxies public methods with blocks through hook labels' do
    result = []
    @hook_proxy.route('One', 'Two') { |*args| result << args }
    result.must_equal [['One', 'Two']]
  end

  it 'allows labels to stick to the yielded values of public methods' do
    # NOTE: this test exercises the slow path in method_missing
    @sticky_proxy.route('One', 'Two') do |*args|
      args.each do |arg|
        Police::DataFlow.labels(arg).must_equal [@sticky_label]
      end
    end
  end

  it 'allows labels to hook into the yielded values of public methods' do
    # NOTE: this test exercises the slow path in method_missing
    @hook_proxy.route('One', 'Two') do |*args|
      args.each { |arg| Police::DataFlow.labels(arg).must_equal [@hook_label] }
    end
  end

  describe 'after proxying public methods with blocks' do
    before do
      @sticky_proxy.route('One', 'Two') { |*args| }
      @hook_proxy.route('One', 'Two') { |*args| }
    end

    it 'defines proxied methods on the fly' do
      @sticky_proxy_class.public_method_defined?(:route).must_equal true
      @sticky_proxy_class.instance_method(:route).owner.must_equal(
          @sticky_proxy_class)
      @hook_proxy_class.public_method_defined?(:route).must_equal true
      @hook_proxy_class.instance_method(:route).owner.must_equal(
          @hook_proxy_class)
    end

    it 'still proxies public methods with blocks through sticky labels' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      result = []
      @sticky_proxy.route('One', 'Two') { |*args| result << args }
      result.must_equal [['One', 'Two']]
    end

    it 'still proxies public methods with blocks through hook labels' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      result = []
      @hook_proxy.route('One', 'Two') { |*args| result << args }
      result.must_equal [['One', 'Two']]
    end

    it 'still allows labels to stick to the yielded values of methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @hook_proxy.route('One', 'Two') do |*args|
        args.each do |arg|
          Police::DataFlow.labels(arg).must_equal [@hook_label]
        end
      end
    end

    it 'still allows labels to hook into the yielded values of methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @hook_proxy.route('One', 'Two') do |*args|
        args.each do |arg|
          Police::DataFlow.labels(arg).must_equal [@hook_label]
        end
      end
    end
  end

  it 'proxies protected methods' do
    # NOTE: this test exercises the slow path in method_missing
    @sticky_proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
    @hook_proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
  end

  it 'allows labels to hook into the return value of protected methods' do
    # NOTE: this test exercises the slow path in method_missing
    Police::DataFlow.labels(@sticky_proxy.__send__(:add, 'One', 'Two')).
        must_equal [@sticky_label]
  end

  it 'allows labels to hook into the return value of protected methods' do
    # NOTE: this test exercises the slow path in method_missing
    Police::DataFlow.labels(@hook_proxy.__send__(:add, 'One', 'Two')).
        must_equal [@hook_label]
  end

  describe 'after proxying protected methods' do
    before do
      @sticky_proxy.__send__ :add, 'One', 'Two'
      @hook_proxy.__send__ :add, 'One', 'Two'
    end

    it 'defines proxied methods on the fly' do
      @sticky_proxy_class.protected_method_defined?(:add).must_equal true
      @sticky_proxy_class.instance_method(:add).owner.must_equal(
          @sticky_proxy_class)
      @hook_proxy_class.protected_method_defined?(:add).must_equal true
      @hook_proxy_class.instance_method(:add).owner.must_equal(
          @hook_proxy_class)
    end

    it 'still proxies protected methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      @sticky_proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
      @hook_proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
    end

    it 'still allows labels to sticky into protected methods' do
      Police::DataFlow.labels(@sticky_proxy.__send__(:add, 'One', 'Two')).
          must_equal [@sticky_label]
    end

    it 'still allows labels to hook into protected methods' do
      # NOTE: this test exercises the auto-generated proxy method's fast path
      Police::DataFlow.labels(@hook_proxy.__send__(:add, 'One', 'Two')).
          must_equal [@hook_label]
    end
  end

  it 'proxies method_missing methods' do
    # NOTE: this test exercises the method_missing+send slow proxying path.
    @sticky_proxy.magic_meth('One', 'Two').must_equal ['meth', 'One', 'Two']
    @hook_proxy.magic_meth('One', 'Two').must_equal ['meth', 'One', 'Two']
  end

  it 'proxies method_missing methods with blocks' do
    # NOTE: this test exercises the method_missing+send slow proxying path.
    @sticky_proxy.magic_meth('One', 'Two') { |*args|
      args.must_equal ['One', 'Two']
      args
    }.must_equal ['meth', ['One', 'Two']]
    @hook_proxy.magic_meth('One', 'Two') { |*args|
      args.must_equal ['One', 'Two']
      args
    }.must_equal ['meth', ['One', 'Two']]
  end

  it 'allows labels to stick to method_missing methods return values' do
    Police::DataFlow.labels(@sticky_proxy.magic_meth('One', 'Two')).
                     must_equal [@sticky_label]
  end

  it 'allows labels to hook into method_missing methods' do
    Police::DataFlow.labels(@hook_proxy.magic_meth('One', 'Two')).
                     must_equal [@hook_label]
  end

  describe 'after proxying method_missing methods' do
    before do
      @sticky_proxy.magic_meth 'One', 'Two'
      @hook_proxy.magic_meth 'One', 'Two'
    end

    it 'does not define proxied methods' do
      @sticky_proxy_class.public_method_defined?(:magic_meth).must_equal false
      @hook_proxy_class.public_method_defined?(:magic_meth).must_equal false
    end
  end

  it 'proxies ==' do
    (@sticky_proxy == nil).must_equal '== proxied'
    (@hook_proxy == nil).must_equal '== proxied'
  end

  it 'proxies !=' do
    (@sticky_proxy != nil).must_equal '!= proxied'
    (@hook_proxy != nil).must_equal '!= proxied'
  end
end
