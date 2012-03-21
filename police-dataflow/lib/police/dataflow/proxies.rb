module Police

module DataFlow

# Namespace for the auto-generated proxy classes.
module Proxies
  # A class whose instances proxy instances of a Ruby class.
  #
  # @param [Class] proxied_class the class whose instances will be proxied by
  #     instances of the returned class
  # @param [Hash<Integer,Hash<Police::DataFlow::Label,Boolean>>] label_set the
  #     set of all labels that will be carried by the proxied object
  # @return [Class] a Police::DataFlow::ProxyBase subclass that can proxy
  #     instances of the given class
  def self.for(proxied_class, label_set)
    unless class_cache = @classes[proxied_class]
      class_cache = {}
      @classes[proxied_class] = class_cache
    end
     
    cache_key = label_set.keys.sort!.freeze
    return class_cache[cache_key] if class_cache.has_key? cache_key
    
    label_classes = label_set.map { |label_key, label_hash|
      label_hash.first.first.class
    }.sort_by!(&:__id__).freeze

    proxy_class = Class.new Police::DataFlow::ProxyBase
    proxy_class.__police_classes__ = label_classes
    class_cache[cache_key] = proxy_class
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
