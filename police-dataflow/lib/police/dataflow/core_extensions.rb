# @private
# The methods below are used by the Police::Dataflow implementation, and
# should not be called directly.
class Object
  # Counterpart to the Police::DataFlow::ProxyBase#__police_labels__ attribute.
  #
  # @return [NilClass] nil, to help the Police::DataFlow implementation
  #     distinguish between "real" objects and label-carrying proxies
  def __police_labels__
    nil
  end
end
