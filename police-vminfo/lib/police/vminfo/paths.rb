module Police
  
module VmInfo
  # True if the given path belongs to a gem.
  def self.gem_path?(path)
    Gem.default_path.any? do |gem_path|
      next false if path.length < gem_path.length
      if path.length > gem_path.length
        path[0, gem_path.length] == gem_path &&
            path[gem_path.length] == File::SEPARATOR
      else
        path == gem_path
      end
    end
    paths = $:
    (0...paths.first.length).each do |i|
      
    end
  end
  def self.stdlib_path
    
  end
end  # module VmInfo

end  # namespace Police