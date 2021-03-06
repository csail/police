require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow do
  before do
    @object = 'Hello'
    @class = @object.class
    @label = StickyFixture.new
  end

  describe '#label' do
    describe 'with a single label' do
      before do
        @object = Police::DataFlow.label @object, @label
      end

      it 'labels the object correctly' do
        Police::DataFlow.labels(@object).must_equal [@label]
      end

      it 'is idempotent' do
        same_object = Police::DataFlow.label @object, @label
        same_object.must_equal @object
        Police::DataFlow.labels(@object).must_equal [@label]
      end

      it 'returns a working proxy' do
        @object.length.must_equal 5
        @object.class.must_equal @class
      end

      it 'returns a label-preserving proxy' do
        @object << ' world'
        @object.length.must_equal 11
        Police::DataFlow.labels(@object).must_equal [@label]
      end
    end

    describe 'with two labels' do
      before do
        @label2 = NoFlowFixture.new
        @object = Police::DataFlow.label @object, @label
        @object = Police::DataFlow.label @object, @label2
      end

      it 'labels the object correctly' do
        Set.new(Police::DataFlow.labels(@object)).
            must_equal Set.new([@label, @label2])
      end
    end
  end
end
