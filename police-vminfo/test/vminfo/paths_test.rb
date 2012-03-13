require File.expand_path('../helper.rb', File.dirname(__FILE__))
require 'net/http'

describe Police::VmInfo do
  def some_method; end

  APP_PATH = Police::VmInfo.method(:gem_path?).source_location.first
  TEST_PATH = self.instance_method(:some_method).source_location.first
  HTTP_PATH = Net::HTTP.method(:new).source_location.first
  BUNDLER_PATH = Bundler.method(:setup).source_location.first
  
  describe 'method_source' do
    it 'recognizes stdlib methods' do
      Police::VmInfo.method_source(Net::HTTP.method(:new)).must_equal :stdlib
    end

    it 'recognizes gem methods' do
      Police::VmInfo.method_source(Bundler.method(:setup)).must_equal :gem
    end

    it 'recognizes app methods' do
      Police::VmInfo.method_source(Police::VmInfo.method(:gem_path?)).
                     must_equal :app
    end
  end
  
  describe 'gem_path?' do
    it 'accepts Bundler path' do
      Police::VmInfo.gem_path?(BUNDLER_PATH).must_equal true
    end

    it 'rejects Net::HTTP path' do
      Police::VmInfo.gem_path?(HTTP_PATH).must_equal false
    end
    
    it 'rejects test path' do
      Police::VmInfo.gem_path?(TEST_PATH).must_equal false
    end

    it 'rejects app path' do
      Police::VmInfo.gem_path?(APP_PATH).must_equal false
    end
  end
  
  describe 'stdlib_path?' do
    it 'rejects Bundler path' do
      Police::VmInfo.stdlib_path?(BUNDLER_PATH).must_equal false
    end

    it 'accepts Net::HTTP path' do
      Police::VmInfo.stdlib_path?(HTTP_PATH).must_equal true
    end
    
    it 'rejects test path' do
      Police::VmInfo.stdlib_path?(TEST_PATH).must_equal false
    end

    it 'rejects app path' do
      Police::VmInfo.stdlib_path?(APP_PATH).must_equal false
    end
  end
  
  describe 'kernel_path?' do
    it 'rejects Bundler path' do
      Police::VmInfo.kernel_path?(BUNDLER_PATH).must_equal false
    end

    it 'rejects Net::HTTP path' do
      Police::VmInfo.kernel_path?(HTTP_PATH).must_equal false
    end
    
    it 'rejects test path' do
      Police::VmInfo.kernel_path?(TEST_PATH).must_equal false
    end

    it 'rejects app path' do
      Police::VmInfo.kernel_path?(APP_PATH).must_equal false
    end
    
    it 'accepts a Rubinius kernel path' do
      Police::VmInfo.kernel_path?('kernel/bootstrap/string.rb').must_equal true
    end
  end
end
