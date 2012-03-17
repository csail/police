require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::DataFlow::Proxies do
  describe '#for' do
    let(:result) do
      Police::DataFlow::Proxies.for ProxyingFixture
    end
    after { Police::DataFlow::Proxies.clear_cache }
    
    it 'creates a Police::DataFlow::ProxyBase subclass' do
      result.superclass.must_equal Police::DataFlow::ProxyBase
    end
    
    it 'caches classes' do
      Police::DataFlow::Proxies.for(ProxyingFixture).must_equal result
    end
    
    it 'creates different proxies for different classes' do
      result.new(ProxyingFixture.new, result).class.must_equal ProxyingFixture
    end
  end
end
