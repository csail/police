module Police
  
module VmInfo
  # Fingerprint for the Ruby VM's core and stdlib API.
  #
  # @return [String] a string that contains the Ruby VM's engine name and
  #     core version; this should be representative of the 
  def self.signature
    Gem.ruby_engine + Gem.ruby_version.segments[0, 3].join('.')
  end
end  # module VmInfo

end  # namespace Police
