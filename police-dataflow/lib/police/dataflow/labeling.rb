module Police

module DataFlow
  # Attaches a label to a piece of data.
  #
  # @param [Object] data the data that will be labeled
  # @param [Police::DataFlow::Label] label the label to be applied to the object
  # @return [BasicObject] either the given piece of data, or a proxy that should
  #     be used instead of it
  def self.label(data, label)
    unless data.__police_labels__
      data = Police::DataFlow::Proxying.proxy data
    end
    data.__police_labels__[label] = true
    data.__police_autoflowing__[label] = true if label.autoflow?
    data
  end
  
  # All the labels attached to a piece of data.
  #
  # @param [Object] data the data whose labels are queried
  # @return [Array<Police::DataFlow::Label>] all the labels attached to the data
  def self.labels(data)
    return [] unless label_hash = data.__police_labels__
    label_hash.keys
  end
end  # namespace Police::DataFlow

end  # namespace Police
