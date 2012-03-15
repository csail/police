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
  def self.route(*rest); end

  # One fixed + variable args.
  def <=>(arg1, *rest); end

  # Two fixed + variable args.
  def self.log(arg1, arg2, *rest); end
  private_class_method :log
end  # class ProxyingFixture

describe Police::DataFlow::Proxying do
  describe '#add_class_method' do
    before do
      @proxy_class = Class.new Police::DataFlow::ProxyBase
      
    end
  end
  
  describe '#proxy_method_definition' do
    it 'returns a non-empty string for a public method' do
      Police::DataFlow::Proxying.proxy_method_body(
          ProxyingFixture.instance_method(:length), :public).length.wont_equal 0
    end

    it 'returns a non-empty string for a private method' do
      Police::DataFlow::Proxying.proxy_method_body(
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
          ProxyingFixture.method(:log), :private, true).must_equal(
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
            ProxyingFixture.method(:route), false).must_equal '*args'
      end
  
      it 'works for one fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:<=>), false).
            must_equal 'arg1, *args'
      end
      
      it 'works for two fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.method(:log), false).must_equal 'arg1, arg2, *args'
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
            ProxyingFixture.method(:route), true).must_equal '*args, &block'
      end
  
      it 'works for one fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.instance_method(:<=>), true).
            must_equal 'arg1, *args, &block'
      end
      
      it 'works for two fixed + variable-argument method' do
        Police::DataFlow::Proxying.proxy_argument_list(
            ProxyingFixture.method(:log), true).
            must_equal 'arg1, arg2, *args, &block'
      end
    end
  end
end
