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
  def self.named_classes
    named_modules.select { |m| m.kind_of? Class }
  end
  
  # All loaded Ruby modules, obtained by 
  def self.all_modules
    
  end
end  # namespace VmInfo

end  # namespace Police
