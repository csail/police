require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::Proxies do
  describe '#for' do
    before do
      @label_set = {}
      Police::DataFlow::Labeling.add_label_to_set NoFlowFixture.new, @label_set
    end

    let(:result) do
      Police::DataFlow::Proxies.for ProxyingFixture, @label_set
    end
    after { Police::DataFlow::Proxies.clear_cache }

    it 'creates a Police::DataFlow::ProxyBase subclass' do
      result.superclass.must_equal Police::DataFlow::ProxyBase
    end

    it 'caches classes' do
      Police::DataFlow::Proxies.for(ProxyingFixture, @label_set).
          must_equal result
    end

    it 'creates different proxies for different classes' do
      Police::DataFlow::Proxies.for(Class.new(ProxyingFixture), @label_set).
          wont_equal result
    end

    it 'creates different proxies for sets of different label classes' do
      label_set = @label_set.clone
      Police::DataFlow::Labeling.add_label_to_set AutoFlowFixture.new,
          label_set
      Police::DataFlow::Proxies.for(ProxyingFixture, label_set).
          wont_equal result
    end
  end
end
