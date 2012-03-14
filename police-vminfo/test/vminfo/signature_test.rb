require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::VmInfo do
  describe '#signature' do
    let(:result) { Police::VmInfo.signature }

    it "should not be empty" do
      result.length.wont_equal 0
    end

    it "should have a bunch of letters, numbers and .s" do
      result.must_match /\A\w+[0-9.]+\Z/
    end
  end
end
