module Police

module DataFlow

# Base class for labeled Numeric replacements.
class ProxyNumeric < ProxyBase
  # Called when a regular Numeric is added, multiplied, etc to a proxied one.
  #
  # Wraps the regular Numeric instance with a proxy, so that call dispatch can
  # take place.
  def coerce(numeric)
    if numeric.__police_labels__
      return [numeric, self]
    end
    proxied_numeric = ::Police::DataFlow::Proxying.proxy numeric, {}, {}
    [proxied_numeric, self]
  end
end

end  # namespace DataFlow

end  # namespace Police
