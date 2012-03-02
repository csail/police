module Police

module VmInfo
  # All loaded Ruby modules, obtained by walking the constants graph.
  def self.named_modules
    # NOTE: this is a Set, but we don't want to load the module.
    explored = { Object => true }
    left = [Object]
    until left.empty?
      namespace = left.pop
      namespace.constants.each do |const_name|
        begin
          const = namespace.const_get const_name
        rescue NameError
          # Delayed loading failure.
          next
        end
        next if explored[const] || !const.kind_of?(Module)
        explored[const] = true
        left.push const
      end
    end
    explored.keys.sort_by(&:name)
  end

  # All loaded Ruby classes, obtained by walking the constants graph.
  #
  # Note that all classes are modules, so this is a subset of named_modules. 
  def self.named_classes
    named_modules.select { |m| m.kind_of? Class }
  end
  
  # All loaded Ruby modules, obtained by querying ObjectSpace. 
  def self.all_modules
    ObjectSpace.each_object(Module).to_a
  end
  
  # All loaded Ruby classes, obtained by querying ObjectSpace. 
  #
  # Note that all classes are modules, so this is a subset of all_modules. 
  def self.all_classes
    ObjectSpace.each_object(Class).to_a
  end
end  # namespace VmInfo

end  # namespace Police
