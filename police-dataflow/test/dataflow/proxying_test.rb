require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::Proxying do
  describe '#create_proxy_class' do
    let(:result) do
      Police::DataFlow::Proxying.create_proxy_class ProxyingFixture
    end
    
    it 'should create a Police::DataFlow::ProxyBase subclass' do
      result.superclass.must_equal Police::DataFlow::ProxyBase
    end
  end
  
  describe '#add_class_methods' do
    before do
      @proxy_class = Class.new(BasicObject) { alias object_id __id__ }
      @proxied = ProxyingFixture.new
      @proxy = @proxy_class.new
      @proxy.instance_exec(@proxied) { |p| @__police_proxied__ = p }

      Police::DataFlow::Proxying.add_class_methods @proxy_class, ProxyingFixture
    end
    
    it 'adds public methods' do
      @proxy_class.public_method_defined?(:length).must_equal true
      @proxy_class.public_method_defined?(:==).must_equal true
      @proxy_class.public_method_defined?(:<=>).must_equal true
    end

    it 'adds a protected method' do
      @proxy_class.protected_method_defined?(:add).must_equal true
    end
    
    it 'adds a private method' do
      @proxy_class.private_method_defined?(:log).must_equal true
    end
  end
  
  describe '#add_class_method' do
    before do
      @proxy_class = Class.new BasicObject
      @proxied = ProxyingFixture.new
      @proxy = @proxy_class.new
      @proxy.instance_exec(@proxied) { |p| @__police_proxied__ = p }
    end
    
    describe 'with protected method with arguments' do
      before do
        @method = ProxyingFixture.instance_method :add
        Police::DataFlow::Proxying.add_class_method @proxy_class, @method,
                                                    :protected
      end
      
      it 'defines the proxying method' do
        @proxy_class.protected_method_defined?(:add).must_equal true        
      end
      
      it "has the proxying method's arity match the original" do
        @proxy_class.instance_method(:add).arity.must_equal @method.arity        
      end
      
      it 'proxies the method' do
        @proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
      end
    end
    
    describe 'with public method with variable arguments and blocks' do
      before do
        @method = ProxyingFixture.instance_method :route
        Police::DataFlow::Proxying.add_class_method @proxy_class, @method,
                                                    :public
      end
      
      it 'defines the proxying method' do
        @proxy_class.public_method_defined?(:route).must_equal true        
      end
      
      it "has the proxying method's arity match the original" do
        @proxy_class.instance_method(:route).arity.must_equal @method.arity        
      end
      
      it 'proxies the method without a block' do
        @proxy.route('One', 'Two').must_equal ['One', 'Two']
      end

      it 'proxies the method with a block' do
        result = []
        @proxy.route 'One', 'Two' do |*args|
          result << args
        end
        result.must_equal [['One', 'Two']]
      end
    end

    it 'proxies protected methods' do
      Police::DataFlow::Proxying.add_class_method @proxy_class,
          ProxyingFixture.instance_method(:add), :protected
      @proxy_class.protected_method_defined?(:add).must_equal true
      @proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
    end
  end
  
  describe '#proxy_method_definition' do
    it 'returns a non-empty string for a public method' do
      Police::DataFlow::Proxying.proxy_method_definition(
          ProxyingFixture.instance_method(:length), :public).length.wont_equal 0
    end

    it 'returns a non-empty string for a private method' do
      Police::DataFlow::Proxying.proxy_method_definition(
          ProxyingFixture.instance_method(:length), :private).length.
          wont_equal 0
    end
    
    # NOTE: testing the actual behavior would just duplicate the tests for
    #       add_class_method
  end
  
  describe '#proxy_method_call' do
    it 'works for a public method without a block' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:length), :public, false).
          must_equal '@__police_proxied__.length()'
    end

    it 'works for a protected method without a block' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:add), :protected, false).
          must_equal '@__police_proxied__.__send__(:add, arg1, arg2)'
    end

    it 'works for a public method with a block' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:length), :public, true).
          must_equal '@__police_proxied__.length(&block)'
    end

    it 'works for a private method with a block' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:length), :private, true).
          must_equal '@__police_proxied__.__send__(:length, &block)'
    end

    it 'works for a private method with arguments and a block' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:log), :private, true).must_equal(
          '@__police_proxied__.__send__(:log, arg1, arg2, *args, &block)')
    end
  end

  describe '#proxy_argument_list' do
    describe 'without block-capturing' do
      it 'works for an argument-less method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:length), false).must_equal ''
      end
  
      it 'works for a one-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:==), false).must_equal 'arg1'
      end
  
      it 'works for a two-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:add), false).
            must_equal 'arg1, arg2'
      end
  
      it 'works for a variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:route), false).must_equal '*args'
      end
  
      it 'works for one fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:<=>), false).
            must_equal 'arg1, *args'
      end
      
      it 'works for two fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:log), false).
            must_equal 'arg1, arg2, *args'
      end
    end

    describe 'with block-capturing' do
      it 'works for an argument-less method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:length), true).must_equal '&block'
      end
  
      it 'works for a one-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:==), true).
            must_equal 'arg1, &block'
      end
  
      it 'works for a two-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:add), true).
            must_equal 'arg1, arg2, &block'
      end
  
      it 'works for a variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:route), true).
            must_equal '*args, &block'
      end
  
      it 'works for one fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:<=>), true).
            must_equal 'arg1, *args, &block'
      end
      
      it 'works for two fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:log), true).
            must_equal 'arg1, arg2, *args, &block'
      end
    end
  end
end
