require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::VmInfo do
  MODULES =  [Kernel, Process::Sys, MiniTest]
  CLASSES = [Object, Encoding::Converter, MiniTest::Unit]    
  
  describe '#named_modules' do
    let(:result) { Police::VmInfo.named_modules }
    (MODULES + CLASSES).each do |const|
      it "contains #{const}" do
        result.must_include const
      end
    end
  end
  
  describe '#named classes' do
    let(:result) { Police::VmInfo.named_classes }

    CLASSES.each do |const|
      it "contains #{const}" do
        result.must_include const
      end
    end
    
    MODULES.each do |const|
      it "does not contain #{const}" do
        result.wont_include const
      end
    end
  end
end
