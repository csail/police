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

    it 'does not contain Bundler' do
      result.wont_include Bundler
    end
  end

  describe '#core_classes' do
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
      let(:methods) { Police::VmInfo.all_methods(fixture_module) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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
      let(:methods) { Police::VmInfo.all_methods(fixture_class) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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
      let(:methods) { Police::VmInfo.class_methods(fixture_module) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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
      let(:methods) { Police::VmInfo.class_methods(fixture_class) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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
      let(:methods) { Police::VmInfo.instance_methods(fixture_module) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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
      let(:methods) { Police::VmInfo.instance_methods(fixture_class) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
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

  describe "#core_class_methods" do
    describe 'on Process' do
      before do
        module Process
          def self.not_a_core_method
          end
        end
      end
      after do
        module Process
          class <<self
            remove_method :not_a_core_method
          end
        end
      end

      let(:methods) { Police::VmInfo.core_class_methods(Process) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
      end

      it 'contains spawn' do
        method_names.must_include :spawn
      end

      it 'does not contain not_a_core_method' do
        method_names.wont_include :not_a_core_method

        # Ensure that the test setup is correct.
        Police::VmInfo.class_methods(Process).map(&:name).
                       must_include :not_a_core_method
      end
    end
  end

  describe "#core_instance_methods" do
    describe 'on Object' do
      before do
        class Object
          def not_a_core_method
          end
        end
      end
      after do
        class Object
          remove_method :not_a_core_method
        end
      end

      let(:methods) { Police::VmInfo.core_instance_methods(Object) }
      let(:method_names) { methods.map(&:name) }

      it 'returns UnboundMethods' do
        methods.each { |method| method.must_be_instance_of UnboundMethod }
      end

      it 'contains ==' do
        method_names.must_include :==
      end

      it 'does not contain not_a_core_method' do
        method_names.wont_include :not_a_core_method

        # Ensure that the test setup is correct.
        Police::VmInfo.instance_methods(Object).map(&:name).
                       must_include :not_a_core_method
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
