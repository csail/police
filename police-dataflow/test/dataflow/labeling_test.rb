require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow do
  before do
    @object = 'Hello'
    @class = @object.class
    @p_label = AutoFlowFixture.new
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
        same_object.__id__.must.equal @object.__id__
        Police::DataFlow.labels(@object).must_equal [@p_label]
      end

      it 'is idempotent vs label type' do

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

      it 'returns a label-enforcing proxy' do
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
end
