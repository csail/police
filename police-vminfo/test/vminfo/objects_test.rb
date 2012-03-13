require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::VmInfo do
  CORE_MODULES = [Kernel, Process::Sys]
  GEM_MODULES = [MiniTest]
  MODULES = CORE_MODULES + GEM_MODULES
  CORE_CLASSES = [Object, Encoding::Converter]
  GEM_CLASSES = [MiniTest::Unit]
  CLASSES = CORE_CLASSES + GEM_CLASSES
  
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
    
    it 'contains anonymous module' do
      anonymous_module = Module.new
      Police::VmInfo.all_modules.must_include anonymous_module
    end

    it 'contains anonymous class' do
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

    it 'does not contain anonymous module' do
      anonymous_module = Module.new
      Police::VmInfo.all_classes.wont_include anonymous_module
    end

    it 'contains anonymous class' do
      anonymous_class = Class.new
      Police::VmInfo.all_classes.must_include anonymous_class
    end
  end

  describe '#core_modules' do
    let(:result) { Police::VmInfo.core_modules }
    
    (CORE_MODULES + CORE_CLASSES).each do |const|
      it "contains #{const}" do
        result.must_include const
      end
    end
    
    (GEM_MODULES + GEM_CLASSES).each do |const|
      it "does not contain #{const}" do
        result.wont_include const
      end
    end
  end
  
  describe '#code_classes' do
    let(:result) { Police::VmInfo.core_classes }

    (CORE_CLASSES).each do |const|
      it "contains #{const}" do
        result.must_include const
      end
    end
    
    (CORE_MODULES + GEM_MODULES + GEM_CLASSES).each do |const|
      it "does not contain #{const}" do
        result.wont_include const
      end
    end
  end    

  def fixture_module
    Module.new do
      include Enumerable
            
      def police_new_module_method; end
      def map; end
      
      def self.dup; end
      def self.police_new_module_class_method; end
    end
  end

  def fixture_class
    Class.new String do
      def police_new_method; end
      def length; end
      
      def self.new; end
      def self.police_new_class_method; end
    end
  end
  
  describe "#all_methods" do
    describe 'on the fixture module' do
      let :method_names do
        Police::VmInfo.all_methods(fixture_module).map(&:name)
      end
      
      it 'contains overridden class methods' do
        method_names.must_include :dup 
      end

      it 'contains new class methods' do
        method_names.must_include :police_new_module_class_method
      end

      it 'does not contain inherited class methods' do
        method_names.wont_include :clone
      end

      it 'contains overridden instance methods' do
        method_names.must_include :map 
      end

      it 'contains new instance methods' do
        method_names.must_include :police_new_module_method
      end

      it 'does not contain inherited instance methods' do
        method_names.wont_include :select
      end
    end
    
    describe 'on the fixture class' do
      let :method_names do
        Police::VmInfo.all_methods(fixture_class).map(&:name)
      end
      
      it 'contains overridden class methods' do
        method_names.must_include :new 
      end

      it 'contains new class methods' do
        method_names.must_include :police_new_class_method
      end

      it 'does not contain inherited class methods' do
        method_names.wont_include :superclass
      end
      
      it 'contains overridden instance methods' do
        method_names.must_include :length 
      end

      it 'contains new instance methods' do
        method_names.must_include :police_new_method
      end

      it 'does not contain inherited instance methods' do
        method_names.wont_include :to_s
      end
    end
  end
  
  describe "#class_methods" do
    describe 'on the fixture module' do
      let :method_names do
        Police::VmInfo.class_methods(fixture_module).map(&:name)
      end
      
      it 'contains overridden methods' do
        method_names.must_include :dup 
      end

      it 'contains new methods' do
        method_names.must_include :police_new_module_class_method
      end

      it 'does not contain inherited class methods' do
        method_names.wont_include :clone
      end

      it 'does not contain instance methods' do
        method_names.wont_include :police_new_module_method
      end
    end
    
    describe 'on the fixture class' do
      let :method_names do
        Police::VmInfo.class_methods(fixture_class).map(&:name)
      end
      
      it 'contains overridden methods' do
        method_names.must_include :new 
      end

      it 'contains new methods' do
        method_names.must_include :police_new_class_method
      end

      it 'does not contain inherited class methods' do
        method_names.wont_include :superclass
      end

      it 'does not contain instance methods' do
        method_names.wont_include :police_new_method
      end
    end
  end  
  
  describe "#instance_methods" do
    describe 'on the fixture module' do
      let :method_names do
        Police::VmInfo.instance_methods(fixture_module).map(&:name)
      end
      
      it 'contains overridden methods' do
        method_names.must_include :map 
      end

      it 'contains new methods' do
        method_names.must_include :police_new_module_method
      end

      it 'does not contain inherited methods' do
        method_names.wont_include :select
      end

      it 'does not contain class methods' do
        method_names.wont_include :police_new_module_class_method
      end
    end
    
    describe 'on the fixture class' do
      let :method_names do
        Police::VmInfo.instance_methods(fixture_class).map(&:name)
      end
      
      it 'contains overridden methods' do
        method_names.must_include :length 
      end

      it 'contains new methods' do
        method_names.must_include :police_new_method
      end

      it 'does not contain inherited methods' do
        method_names.wont_include :to_s
      end

      it 'does not contain class methods' do
        method_names.wont_include :police_new_class_method
      end
    end
  end
  
  describe "#constantize" do
    it 'works on simple names' do
      Police::VmInfo.constantize('Object').must_equal Object
    end

    it 'works on scoped names' do
      Police::VmInfo.constantize('Process::Sys').must_equal Process::Sys
    end

    it 'works on global scoped names' do
      Police::VmInfo.constantize('::Process::Sys').must_equal Process::Sys
    end
  end
end
