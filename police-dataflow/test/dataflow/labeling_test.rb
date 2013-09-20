require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow do
  before do
    @object = 'Hello'
    @class = @object.class
    @p_label = StickyFixture.new
  end

  describe '#label' do
    describe 'with a single label' do
      before do
        @object = Police::DataFlow.label @object, @p_label
      end

      it 'labels the object correctly' do
        Police::DataFlow.labels(@object).must_equal [@p_label]
      end

      it 'is idempotent' do
        same_object = Police::DataFlow.label @object, @p_label
        same_object.must_equal @object
        same_object.__id__.must_equal @object.__id__
        Police::DataFlow.labels(@object).must_equal [@p_label]
      end

      it 'is idempotent vs label type' do
        p_label2 = StickyFixture.new
        same_object = Police::DataFlow.label @object, p_label2
        same_object.must_equal @object
        same_object.__id__.must_equal @object.__id__
        Police::DataFlow.labels(@object).sort_by(&:__id__).must_equal(
            [@p_label, p_label2].sort_by(&:__id__))
      end

      it 'returns a working proxy' do
        @object.length.must_equal 5
        @object.class.must_equal @class
      end

      it 'returns a label-preserving proxy' do
        @object << ' world'
        @object.length.must_equal 11
        Police::DataFlow.labels(@object).must_equal [@p_label]
      end

      it 'returns a label-propagating proxy' do
        Police::DataFlow.labels(@object[2..5]).must_equal [@p_label]
      end
    end

    describe 'with two labels' do
      before do
        @n_label = NoFlowFixture.new
        @object = Police::DataFlow.label @object, @p_label
        @object = Police::DataFlow.label @object, @n_label
      end

      it 'labels the object correctly' do
        Set.new(Police::DataFlow.labels(@object)).
            must_equal Set.new([@p_label, @n_label])
      end

      it 'propagates the labels correctly' do
        Police::DataFlow.labels(@object[2..5]).must_equal [@p_label]
      end
    end

    describe 'on built-in Fixnums' do
      before do
        @number = Police::DataFlow.label 21, @p_label
      end

      it 'returns a working proxy' do
        (@number * 2).must_equal 42
        (2 * @number).must_equal 42
      end

      it 'returns a label-propagating proxy' do
        Police::DataFlow.labels(@number * 2).must_equal [@p_label]
      end

      it 'returns a proxy that coerces numbers correctly' do
        Police::DataFlow.labels(2 * @number).must_equal [@p_label]
      end
    end
  end

  describe '#labels' do
    it 'returns an empty array for un-labeled objects' do
      Police::DataFlow.labels(@object).must_equal []
    end

    it 'returns a populated array for labeled objects' do
      labeled = Police::DataFlow.label @object, @p_label
      Police::DataFlow.labels(labeled).must_equal [@p_label]
    end
  end

  describe '#proxy_class' do
    it 'returns nil for un-labeled objects' do
      Police::DataFlow.proxy_class(@object).must_equal nil
    end

    describe 'for proxied objects' do
      before do
        @labeled = Police::DataFlow.label @object, @p_label
      end

      it 'returns a ProxyBase subclass' do
        Police::DataFlow.proxy_class(@labeled).superclass.must_equal(
            Police::DataFlow::ProxyBase)
      end

      it "returns the proxy's real class" do
        klass = Police::DataFlow.proxy_class @labeled
        klass.class_eval do
          def boom
            'headshot'
          end
        end
        lambda { @object.boom }.must_raise NoMethodError
        @labeled.boom.must_equal 'headshot'
      end
    end
  end
end
