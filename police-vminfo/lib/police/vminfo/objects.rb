module Police

module VmInfo
  # All loaded Ruby modules, obtained by walking the constants graph.
  #
  # @return [Array<Module>] the Ruby modules that could be discovered by
  #     searching the constants graph; this should include everything except for
  #     anonymous (not assigned to constants) classes
  def self.named_modules
    # NOTE: this is a Set, but we don't want to load the module.
    explored = { Object => true }
    left = [Object]
    until left.empty?
      namespace = left.pop
      namespace.constants.each do |const_name|
        begin
          const = if namespace.const_defined? const_name
            namespace.const_get const_name
          else
            namespace.const_missing const_name
          end
        rescue LoadError, NameError
          # Delayed loading failure.
          next
        end
        next if explored[const] || !const.kind_of?(Module)
        explored[const] = true
        left.push const
      end
    end
    explored.keys.sort_by!(&:name).freeze
  end

  # All loaded Ruby classes, obtained by walking the constants graph.
  #
  # Note that all classes are modules, so this is a subset of named_modules.
  #
  # @return [Array<Module>] the Ruby classes that could be discovered by
  #     searching the constants graph; this should include everything except for
  #     anonymous (not assigned to constants) classes
  def self.named_classes
    named_modules.select { |m| m.kind_of? Class }
  end
  
  # All loaded Ruby modules, obtained by querying ObjectSpace. 
  #
  # Querying ObjectSpace can be painfully slow, especially on non-MRI VMs.
  #
  # @return [Array<Module>] all the Ruby modules
  def self.all_modules
    ObjectSpace.each_object(Module).to_a
  end
  
  # All loaded Ruby classes, obtained by querying ObjectSpace. 
  #
  # Querying ObjectSpace can be painfully slow, especially on non-MRI VMs. Note
  # that all classes are modules, so this is a subset of all_modules. 
  #
  # @return [Array<Classes>] all the Ruby classes
  def self.all_classes
    ObjectSpace.each_object(Class).to_a
  end
  
  # The modules making up the Ruby VM implementation.
  #
  # @return [Array<Module>] the modules that are present in a vanilla Ruby
  #     environment
  def self.core_modules
    output =
        `#{Gem.ruby} -e 'puts ObjectSpace.each_object(Module).to_a.join("\n")'`
    modules = []
    output.split("\n").each do |name|
      next if name[0] == ?#
      begin
        mod = constantize name
        next unless mod.kind_of? Module
        modules << mod
      rescue NameError, LoadError
        # Delayed loading failure.
        next
      end
    end
    modules
  end
  
  # The classes making up the Ruby VM implementation.
  #
  # Note that all classes are modules, so this is a subset of core_modules.  
  #
  # @return [Array<Class>] the classes that are present in a vanilla Ruby
  #     environment
  def self.core_classes
    core_modules.select { |m| m.kind_of? Class }
  end
  
  # All methods defined in a class or module.
  #
  # @param [Module] module_or_class a Class or Module instance
  # @return [Array<Method, UnboundMethod>] all the class and instance methods
  #     defined by the given Class or Module
  def self.all_methods(module_or_class)
    class_methods(module_or_class) + instance_methods(module_or_class)
  end

  # All instance methods defined in a class or module.
  #
  # @param [Module] module_or_class a Class or Module instance
  # @return [Array<Method, UnboundMethod>] all the instance methods defined by
  #     the given Class or Module
  def self.instance_methods(module_or_class)
    module_or_class.instance_methods.tap do |array|
      array.map! { |name| module_or_class.instance_method name }
      array.select! { |method| method.owner == module_or_class }
    end
  end

  # All class methods defined in a class or module.
  #
  # Note: the class methods of a class or module are the instance methods of the
  # class or module's meta-class.
  #
  # @param [Module] module_or_class a Class or Module instance
  # @return [Array<Method, UnboundMethod>] all the instance methods defined by
  #     the given Class or Module
  def self.class_methods(module_or_class)
    # NOTE: this long-winded approach avoids creating new singleton classes
    method_names = module_or_class.singleton_methods
    return [] if method_names.empty?
    singleton_class = module_or_class.singleton_class
    method_names.tap do |array|
      array.map! { |name| module_or_class.method name }
      array.select! { |method| method.owner == singleton_class }
    end
  end
  
  # Resolves the name of a constant into its value.
  #
  # @param [String] name a constant name, potentially including the scope
  #     operator ::
  # @return [Object] the value of the constant with the given name
  # @raise [NameError] no constant with the given name is defined
  def self.constantize(name)
    segments = name.split '::'
    value = Object
    segments.each do |name|
      next if name.empty?
      value = if value.const_defined? name
        value.const_get name
      else
        value.const_missing name
      end
    end
    value    
  end
end  # namespace VmInfo

end  # namespace Police
