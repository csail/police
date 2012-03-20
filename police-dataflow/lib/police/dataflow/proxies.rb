module Police

module DataFlow

# Namespace for the auto-generated proxy classes.
module Proxies
  # A class whose instances proxy instances of a Ruby class.
  #
  # @param [Array<Class>] classes the classes whose instances will be proxied by
  #     instances of the returned class; the array's contents will be trashed
  # @return [Class] a Police::DataFlow::ProxyBase subclass that can proxy
  #     instances of the given class
  def self.for(classes)
    cache_key = classes.sort_by!(&:id)
    return @classes[cache_key] if @classes.has_key? hash_key
    
    proxy_class = Class.new Police::DataFlow::ProxyBase
    proxy_class.__police_classes__ = classes.dup.freeze
    @classes[cache_key] = proxy_class
    proxy_class
  end

  # Clears the cache of proxy classes associated with Ruby classes.
  #
  # This method has a terrible impact on VM performance, and is only intended
  # for testing the Police::DataFlow implementation.
  #
  # @return [Boolean] true
  def self.clear_cache
    @classes.clear
    true
  end

  # Maps Ruby classes to auto-generated proxy classes.
  @classes = {}
end  # namespace Police::DataFlow::Proxies

end  # namespace Police::DataFlow

end  # namespace Police
