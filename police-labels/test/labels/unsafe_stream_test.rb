require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::Labels::UnsafeStream do
  let(:unsafe_label) { Police::Labels::UnsafeString.new }
  let(:label) { Police::Labels::UnsafeStream.new unsafe_label } 

  it 'accepts STDIN' do
    label.accepts?(STDIN).must_equal true
  end
  
  it 'does not accept strings' do
    label.accepts?('Some string').must_equal false
  end
  
  it 'accepts a StringIO' do
    label.accepts?(StringIO.new('Some string')).must_equal true
  end
end
