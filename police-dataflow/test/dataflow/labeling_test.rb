require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow do
  before do
    @object = 'Hello'
    @class = @object.class
    @p_label = StickyFixture.new
  end

  describe '.label' do
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

  describe '.labels' do
    it 'returns an empty array for un-labeled objects' do
      Police::DataFlow.labels(@object).must_equal []
    end

    it 'returns a populated array for labeled objects' do
      labeled = Police::DataFlow.label @object, @p_label
      Police::DataFlow.labels(labeled).must_equal [@p_label]
    end
  end

end

describe Police::DataFlow::Labeling do
  before do
    @n1_label = NoFlowFixture.new
    @n2_label = NoFlowFixture.new
    @s1_label = StickyFixture.new
    @s2_label = StickyFixture.new
    @h1_label = HooksFlowFixture.new
  end

  describe '.add_label_to_set' do
    before do
      @set = {
        NoFlowFixture.__id__ => {
          @n1_label => true,
          @n2_label => true
        },
        StickyFixture.__id__ => {
          @s1_label => true
        }
      }
      @set_n = @set[NoFlowFixture.__id__]
      @set_s = @set[StickyFixture.__id__]
    end

    it 'no-ops when the label is in the set' do
      Police::DataFlow::Labeling.add_label_to_set(@n1_label, @set).must_equal(
          false)
      @set[NoFlowFixture.__id__].__id__.must_equal @set_n.__id__
    end

    it 'adds labels to existing groups' do
      Police::DataFlow::Labeling.add_label_to_set(@s2_label, @set).must_equal(
          false)
      @set[StickyFixture.__id__].__id__.must_equal @set_s.__id__
      @set[StickyFixture.__id__].must_equal @s1_label => true,
                                            @s2_label => true
    end

    it 'creates new groups when necessary' do
      Police::DataFlow::Labeling.add_label_to_set(@h1_label, @set).must_equal(
          true)
      @set[HooksFlowFixture.__id__].must_equal @h1_label => true
    end
  end

  describe '.merge_sets!' do
    before do
      @target = {
        NoFlowFixture.__id__ => {
          @n1_label => true,
          @n2_label => true
        },
        StickyFixture.__id__ => {
          @s1_label => true
        }
      }
      @target_n = @target[NoFlowFixture.__id__]
      @target_s = @target[StickyFixture.__id__]
      @source = {
        NoFlowFixture.__id__ => {
          @n2_label => true
        },
        StickyFixture.__id__ => {
          @s2_label => true
        },
        HooksFlowFixture.__id__ => {
          @h1_label => true
        }
      }
      Police::DataFlow::Labeling.merge_sets! @target, @source
    end

    it 'behaves when target is a superset of source' do
      @target[NoFlowFixture.__id__].must_equal(
          @n1_label => true, @n2_label => true)
    end

    it 'merges label sets' do
      @target[StickyFixture.__id__].must_equal(
          @s1_label => true, @s2_label => true)
    end

    it 'adds missing sets' do
      @target[HooksFlowFixture.__id__].must_equal @h1_label => true
    end

    it 'does not create unnecessary objects' do
      @target[NoFlowFixture.__id__].__id__.must_equal @target_n.__id__
      @target[StickyFixture.__id__].__id__.must_equal @target_s.__id__
    end

    it 'does not reuse source objects' do
      @target[HooksFlowFixture.__id__].__id__.wont_equal(
          @source[HooksFlowFixture.__id__].__id__)
    end
  end

  describe '.bulky_sticky_label' do
    before do
      @set = {
        NoFlowFixture.__id__ => {
          @n1_label => true,
          @n2_label => true
        },
        StickyFixture.__id__ => {
          @s1_label => true
        }
      }
      @set_n = @set[NoFlowFixture.__id__]
      @set_s = @set[StickyFixture.__id__]
    end

    describe 'with an unlabeled object' do
      before do
        @object = 'Hello'
        @labeled = Police::DataFlow::Labeling.bulk_sticky_label @object, @set
      end

      it 'labels the object correctly' do
        Police::DataFlow.labels(@labeled).sort_by(&:__id__).must_equal(
            [@n1_label, @n2_label, @s1_label].sort_by(&:__id__))
      end

      it 'proxies the object correctly' do
        @labeled.length.must_equal 5
        @labeled[1].must_equal 'e'
      end

      it 'does not reuse the label set' do
        @labeled.__police_labels__.__id__.wont_equal @set.__id__
        @labeled.__police_stickies__.__id__.wont_equal @set.__id__
        @labeled.__police_labels__[NoFlowFixture.__id__].__id__.wont_equal(
            @set_n.__id__)
        @labeled.__police_labels__[StickyFixture.__id__].__id__.wont_equal(
            @set_s.__id__)
      end
    end

    describe 'with a labeled object with enough groups' do
      before do
        @original = 'Hello'
        @object = Police::DataFlow.label @original, @n1_label
        @object = Police::DataFlow.label @object, @s2_label
        @object = Police::DataFlow.label @object, @h1_label

        @set2_n = @object.__police_labels__[NoFlowFixture.__id__]
        @set2_s = @object.__police_labels__[StickyFixture.__id__]

        @labeled = Police::DataFlow::Labeling.bulk_sticky_label @object, @set
      end

      it 'labels the object correctly' do
        Police::DataFlow.labels(@labeled).sort_by(&:__id__).must_equal(
            [@n1_label, @n2_label, @s1_label, @s2_label, @h1_label].
            sort_by(&:__id__))
      end

      it 'proxies the object correctly' do
        @labeled.length.must_equal 5
        @labeled[1].must_equal 'e'
      end

      it 'reuses the proxy' do
        @object.__id__.must_equal @labeled.__id__
        Police::DataFlow::Labeling.proxy_class(@object).must_equal(
            Police::DataFlow::Labeling.proxy_class(@labeled))
      end

      it 'reuses the label set groups' do
        @object.__police_labels__[NoFlowFixture.__id__].__id__.must_equal(
            @set2_n.__id__)
        @object.__police_labels__[StickyFixture.__id__].__id__.must_equal(
            @set2_s.__id__)
      end
    end

    describe 'with a labeled object that needs a new group' do
      before do
        @original = 'Hello'
        @object = Police::DataFlow.label @original, @n1_label
        @object = Police::DataFlow.label @object, @h1_label

        @set2_n = @object.__police_labels__[NoFlowFixture.__id__]

        @labeled = Police::DataFlow::Labeling.bulk_sticky_label @object, @set
      end

      it 'labels the object correctly' do
        Police::DataFlow.labels(@labeled).sort_by(&:__id__).must_equal(
            [@n1_label, @n2_label, @s1_label, @h1_label].
            sort_by(&:__id__))
      end

      it 'proxies the object correctly' do
        @labeled.length.must_equal 5
        @labeled[1].must_equal 'e'
      end

      it 'creates a new proxy' do
        @object.__id__.wont_equal @labeled.__id__
        Police::DataFlow::Labeling.proxy_class(@object).wont_equal(
            Police::DataFlow::Labeling.proxy_class(@labeled))
      end

      it 'reuses label set groups when possible' do
        @object.__police_labels__[NoFlowFixture.__id__].__id__.must_equal(
            @set2_n.__id__)
      end
    end
  end

  describe '.dup' do
    before do
      @set = {
        NoFlowFixture.__id__ => {
          @n1_label => true,
          @n2_label => true
        },
        StickyFixture.__id__ => {
          @s1_label => true
        }
      }
      @set_n = @set[NoFlowFixture.__id__]
      @set_s = @set[StickyFixture.__id__]
      @copy = Police::DataFlow::Labeling.dup_set @set
    end

    it 'does not change the source set' do
      @set[NoFlowFixture.__id__].__id__.must_equal @set_n.__id__
      @set[StickyFixture.__id__].__id__.must_equal @set_s.__id__
      @set_n.must_equal @n1_label => true, @n2_label => true
      @set_s.must_equal @s1_label => true
    end

    it 'copies the groups in the source set' do
      @copy[NoFlowFixture.__id__].must_equal @n1_label => true,
                                             @n2_label => true
      @copy[StickyFixture.__id__].must_equal @s1_label => true
    end

    it 'does not reuse the groups in the source set' do
      @copy[NoFlowFixture.__id__].__id__.wont_equal @set_n.__id__
      @copy[StickyFixture.__id__].__id__.wont_equal @set_s.__id__
    end

    it 'does not create new groups' do
      @copy.keys.must_equal [NoFlowFixture.__id__, StickyFixture.__id__]
    end
  end

  describe '.proxy_class' do
    before do
      @object = 'Hello'
    end

    it 'returns nil for un-labeled objects' do
      Police::DataFlow::Labeling.proxy_class(@object).must_equal nil
    end

    describe 'for proxied objects' do
      before do
        @labeled = Police::DataFlow.label @object, @s1_label
      end

      it 'returns a ProxyBase subclass' do
        Police::DataFlow::Labeling.proxy_class(@labeled).superclass.must_equal(
            Police::DataFlow::ProxyBase)
      end

      it "returns the proxy's real class" do
        klass = Police::DataFlow::Labeling.proxy_class @labeled
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
