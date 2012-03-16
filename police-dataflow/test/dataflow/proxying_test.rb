require File.expand_path('../helper.rb', File.dirname(__FILE__))

class ProxyingFixture
  # Zero arguments.
  def length; end
  
  # One argument.
  def ==(other); end
  
  # Two arguments.
  def add(arg1, arg2)
    "#{arg1}, #{arg2}"
  end
  protected :add
  
  # Variable args.
  def route(*rest)
    if block_given?
      yield *rest
    else
      rest
    end
  end

  # One fixed + variable args.
  def <=>(arg1, *rest); end

  # Two fixed + variable args.
  def log(arg1, arg2, *rest); end
  private :log
end  # class ProxyingFixture

describe Police::DataFlow::Proxying do
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
      
      it 'should define the proxying method' do
        @proxy_class.protected_method_defined?(:add).must_equal true        
      end
      
      it "should have the proxying method's arity match the original" do
        @proxy_class.instance_method(:add).arity.must_equal @method.arity        
      end
      
      it 'should proxy the method' do
        @proxy.__send__(:add, 'One', 'Two').must_equal 'One, Two'
      end
    end
    
    describe 'with public method with variable arguments and blocks' do
      before do
        @method = ProxyingFixture.instance_method :route
        Police::DataFlow::Proxying.add_class_method @proxy_class, @method,
                                                    :public
      end
      
      it 'should define the proxying method' do
        @proxy_class.public_method_defined?(:route).must_equal true        
      end
      
      it "should have the proxying method's arity match the original" do
        @proxy_class.instance_method(:route).arity.must_equal @method.arity        
      end
      
      it 'should proxy the method without a block' do
        @proxy.route('One', 'Two').must_equal ['One', 'Two']
      end

      it 'should proxy the method with a block' do
        result = []
        @proxy.route 'One', 'Two' do |*args|
          result << args
        end
        result.must_equal [['One', 'Two']]
      end
    end

    it 'should proxy public methods that take blocks' do
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
