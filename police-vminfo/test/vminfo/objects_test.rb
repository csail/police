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
  
  describe '#named_classes' do
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

  describe '#all_modules' do
    let(:result) { Police::VmInfo.all_modules }
    (MODULES + CLASSES).each do |const|
      it "contains #{const}" do
        result.must_include const
      end
    end
    
    it "contains anonymous module" do
      anonymous_module = Module.new
      Police::VmInfo.all_modules.must_include anonymous_module
    end

    it "contains anonymous class" do
      anonymous_class = Class.new
      Police::VmInfo.all_modules.must_include anonymous_class
    end
  end
  
  describe '#all_classes' do
    let(:result) { Police::VmInfo.all_classes }

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

    it "does not contain anonymous module" do
      anonymous_module = Module.new
      Police::VmInfo.all_classes.wont_include anonymous_module
    end

    it "contains anonymous class" do
      anonymous_class = Class.new
      Police::VmInfo.all_classes.must_include anonymous_class
    end
  end
end
