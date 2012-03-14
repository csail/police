module Police
  
module VmInfo
  # Classifies the path to a Ruby file based on its provenance.
  #
  # @param [Method, UnboundMethod] method VM information about a method; usually
  #     obtained by calling Object#method or Module#instance_method
  # @return [Symbol] :native for methods defined in a low-level language (C/C++
  #     for MRI and Rubinius, Java for JRuby), :kernel for methods belonging to
  #     the core VM code (Rubinius and JRuby), :stdlib for methods in Ruby's
  #     standard library, :gem for methods that are implemented in a loaded Ruby
  #     gem, and :app for all other methods (presumably defined in the current
  #     application)
  def self.method_source(method)
    location = method.source_location
    return :native if location.nil?
    code_path = location.first
    return :stdlib if stdlib_path?(code_path)
    return :gem if gem_path?(code_path)
    return :kernel if kernel_path?(code_path)
    :app
  end
  
  # True if the given source code path belongs to a gem.
  def self.gem_path?(path)
    Gem.default_path.any? { |gem_path| Paths.descendant? path, gem_path }
  end
  
  # True if the given source code path belongs to the Ruby standard library.
  def self.stdlib_path?(path)
    # NOTE: assuming the convention that all directories are prepended to the
    #       load path throughout a program's execution
    load_paths = $LOAD_PATH    
    last_gem_index = -1
    (load_paths.length - 1).downto(0) do |index|
      if gem_path? load_paths[index]
        last_gem_index = index
        break
      end
    end
    stdlib_paths = load_paths[(last_gem_index + 1)..-1]
    stdlib_paths.any? { |stdlib_path| Paths.descendant? path, stdlib_path }
  end
  
  # True if the given source code path belongs to the Ruby VM kernel.
  def self.kernel_path?(path)
    !$LOAD_PATH.any? { |load_path| Paths.descendant? path, load_path }
  end
  
  # Implementation details.
  # @private
  module Paths
    class <<self
      # True if a path points to a descendant of the directory in anothe
      def descendant?(descendant, dir)
        if descendant.length > dir.length
          descendant[0, dir.length] == dir &&
              descendant[dir.length] == File::SEPARATOR
        else
          descendant == dir
        end
      end
    end
  end
end  # module VmInfo

end  # namespace Police
