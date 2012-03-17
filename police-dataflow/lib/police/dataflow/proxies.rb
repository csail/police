module Police

module DataFlow

# Namespace for the auto-generated proxy classes.
module Proxies
  # A class whose instances proxy instances of a Ruby class.
  #
  # @param [Class] klass the class whose instances will be proxied by instances
  #     of the returned class
  # @return [Class] a Police::DataFlow::ProxyBase subclass that can proxy
  #     instances of the given class
  def self.for(klass)
    return @classes[klass] if @classes.has_key? klass
    proxy_class = Class.new Police::DataFlow::ProxyBase
    @classes[klass] = proxy_class
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
