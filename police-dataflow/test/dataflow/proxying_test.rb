require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::Proxying do
  describe '#add_class_methods' do
    before do
      @proxy_class = Class.new BasicObject do
        def self.__police_classes__
          [NoFlowFixture]
        end
        alias object_id __id__
      end
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
      @proxy_class = Class.new BasicObject do
        def self.__police_classes__
          []
        end
      end
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
        @proxy.route('One', 'Two') { |*args| result << args }
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
      Police::DataFlow::Proxying.proxy_method_definition([AutoFlowFixture],
          ProxyingFixture.instance_method(:length), :public).length.wont_equal 0
    end

    it 'returns a non-empty string for a private method' do
      Police::DataFlow::Proxying.proxy_method_definition([AutoFlowFixture],
          ProxyingFixture.instance_method(:length), :private).length.
          wont_equal 0
    end

    # NOTE: testing the actual behavior would just duplicate the tests for
    #       add_class_method
  end

  describe '#proxy_method_call' do
    it 'works for a public method' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:length), :public).
          must_equal '@__police_proxied__.length()'
    end

    it 'works for a protected method' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:add), :protected).
          must_equal '@__police_proxied__.__send__(:add, arg1, arg2)'
    end

    it 'works for a private method' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:length), :private).
          must_equal '@__police_proxied__.__send__(:length)'
    end

    it 'works for a private method with arguments' do
      Police::DataFlow::Proxying.proxy_method_call(
          ProxyingFixture.instance_method(:log), :private).must_equal(
          '@__police_proxied__.__send__(:log, arg1, arg2, *args)')
    end
  end

  describe '#proxy_yield_args_decorating' do
    let(:method) { ProxyingFixture.instance_method(:add) }

    it 'is empty if no label class is filtering' do
      Police::DataFlow::Proxying.proxy_yield_args_decorating([NoFlowFixture],
          method).must_equal ''
    end

    it 'works for one filtering label class' do
      golden = 'labels = @__police_labels__; ' \
        "labels[#{AutoFlowFixture.__id__}].each { |label, _| " \
          "label.sample_yield_args_hook(self, yield_args, arg1, arg2) }"
      Police::DataFlow::Proxying.proxy_yield_args_decorating(
          [NoFlowFixture, AutoFlowFixture], method).must_equal golden
    end

    it 'works for two filtering label classes' do
      label2_class = Class.new BasicObject do
        def self.yield_args_hook(method_name)
          :"#{method_name}_ah"
        end
      end
      golden = 'labels = @__police_labels__; ' \
        "labels[#{AutoFlowFixture.__id__}].each { |label, _| " \
          "label.sample_yield_args_hook(self, yield_args, arg1, arg2) }; " \
        "labels[#{label2_class.__id__}].each { |label, _| " \
          "label.add_ah(self, yield_args, arg1, arg2) }"
      Police::DataFlow::Proxying.proxy_yield_args_decorating([NoFlowFixture,
          AutoFlowFixture, label2_class], method).must_equal golden
    end
  end

  describe '#proxy_return_decorating' do
    let(:method) { ProxyingFixture.instance_method(:add) }

    it 'is empty if no label class is filtering' do
      Police::DataFlow::Proxying.proxy_return_decorating([NoFlowFixture],
          method).must_equal ''
    end

    it 'works for one filtering label class' do
      golden = 'labels = @__police_labels__; ' \
        "labels[#{AutoFlowFixture.__id__}].each { |label, _| " \
          "return_value = label.sample_return_hook(return_value, self, arg1, " \
                                                  "arg2) }"
      Police::DataFlow::Proxying.proxy_return_decorating(
          [NoFlowFixture, AutoFlowFixture], method).must_equal golden
    end

    it 'works for two filtering label classes' do
      label2_class = Class.new BasicObject do
        def self.return_hook(method_name)
          :"#{method_name}_rh"
        end
      end
      golden = 'labels = @__police_labels__; ' \
        "labels[#{AutoFlowFixture.__id__}].each { |label, _| " \
          "return_value = label.sample_return_hook(return_value, self, arg1, " \
                                                  "arg2) }; " \
        "labels[#{label2_class.__id__}].each { |label, _| " \
          "return_value = label.add_rh(return_value, self, arg1, arg2) }"
      Police::DataFlow::Proxying.proxy_return_decorating([NoFlowFixture,
          AutoFlowFixture, label2_class], method).must_equal golden
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

  describe '#proxy_call_argument_list' do
    it 'uses proxy_argument_list for Ruby methods' do
      Police::DataFlow::Proxying.proxy_call_argument_list(
          ProxyingFixture.instance_method(:==)).must_equal 'arg1'
    end

    it 'uses low_level_call_argument_list for native methods' do
      golden =
          '(nil == arg1.__police_labels__) ? arg1 : arg1.__police_proxied__'
      Police::DataFlow::Proxying.proxy_call_argument_list(
          Object.instance_method(:==)).must_equal golden
    end
  end

  describe '#proxy_low_level_call_argument_list' do
    it 'works for an argument-less method' do
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:length)).must_equal ''
    end

    it 'works for a one-argument method' do
      golden =
          '(nil == arg1.__police_labels__) ? arg1 : arg1.__police_proxied__'
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:==)).must_equal golden
    end

    it 'works for a two-argument method' do
      golden =
          '(nil == arg1.__police_labels__) ? arg1 : arg1.__police_proxied__, ' +
          '(nil == arg2.__police_labels__) ? arg2 : arg2.__police_proxied__'
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:add)).must_equal golden
    end

    it 'works for a variable-argument method' do
      golden = '*(args.map { |a| (nil == a.__police_labels__) ? a : ' +
          'a.__police_proxied__ })'
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:route)).must_equal golden
    end

    it 'works for one fixed + variable-argument method' do
      golden =
          '(nil == arg1.__police_labels__) ? arg1 : arg1.__police_proxied__, ' +
          '*(args.map { |a| (nil == a.__police_labels__) ? a : ' +
          'a.__police_proxied__ })'
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:<=>)).must_equal golden
    end

    it 'works for two fixed + variable-argument method' do
      golden =
          '(nil == arg1.__police_labels__) ? arg1 : arg1.__police_proxied__, ' +
          '(nil == arg2.__police_labels__) ? arg2 : arg2.__police_proxied__, ' +
          '*(args.map { |a| (nil == a.__police_labels__) ? a : ' +
          'a.__police_proxied__ })'
      Police::DataFlow::Proxying.proxy_low_level_call_argument_list(
          ProxyingFixture.instance_method(:log)).must_equal golden
    end
  end
end
