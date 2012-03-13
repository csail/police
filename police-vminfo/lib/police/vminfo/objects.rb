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
  #     environment and have at least one native method
  def self.core_modules
    output =
        `#{Gem.ruby} -e 'puts ObjectSpace.each_object(Module).to_a.join("\n")'`
    output.split("\n").each do |name|
      
    end
  end
  
  # Resolves the name of a constant into its value.
  #
  # @param [String] name a constant name, potentially including the scope
  #     operator ::
  # @return [Object] the value of the constant with the given name
  # @raise NameError no constant with the given name is defined
  def self.constantize(name)
    segments = name.split '::'
    value = Object
    names.each do |name|
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
