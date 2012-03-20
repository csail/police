module Police

module DataFlow
  # Attaches a label to a piece of data.
  #
  # @param [Object] data the data that will be labeled
  # @param [Police::DataFlow::Label] label the label to be applied to the object
  # @return [BasicObject] either the given piece of data, or a proxy that should
  #     be used instead of it
  def self.label(data, label)
    labels_hash = data.__police_labels__
    if labels_hash.nil?
      # Unlabeled data.
      proxied = data
      labels_hash = {}
      autoflows_hash = {}
    else
      proxied = data.__police_proxied__
      autoflows_hash = data.__police_autoflows__
    end
    
    label_key = label.class.__id__
    if labels_hash.has_key? label_key
      # The object already has this kind of label. 
      labels[label_key][label] = true
    else
      # This is a new kind of label, so we need to create a new proxy.
      label_entry = { label => true}
      labels_hash[label_key] = label_entry
      autoflows_hash[label_key] = label_entry
      
      
      data.__police_autoflowing__[label] = label_hash if label.autoflow?
      
      data = Police::DataFlow::Proxying.proxy label.class
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
