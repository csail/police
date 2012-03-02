module Police
  
module VmInfo
  # True if the given source code path belongs to a gem.
  def self.gem_path?(path)
    Gem.default_path.any? { |gem_path| Paths.descendant? path, gem_path }
  end
  
  # True if the given source code path belongs to the Ruby standard library.
  def self.stdlib_path?(path)
    # NOTE: assuming the convention that all directories are prepended to the
    #       load path throughout a program's execution
    load_paths = $LOAD_PATH    
    last_gem_index = 0
    (load_paths.length - 1).downto(0) do |index|
      if gem_path? load_paths[index]
        last_gem_index = index
        break
      end
    end
    stdlib_paths = load_paths[((last_gem_index || -1) + 1)..-1]
    stdlib_paths.any? { |stdlib_path| Paths.descendant? path, stdlib_path }
  end
  
  # True if the given source code path belongs to the Ruby VM kernel.
  def self.kernel_path?(path)
    !$LOAD_PATH.any? { |load_path| Paths.descendant? path, load_path }
  end
  
  # Implementation details.  
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