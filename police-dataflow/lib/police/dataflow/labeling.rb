module Police

module DataFlow
  # Attaches a label to a piece of data.
  #
  # @param [BasicObject] data the data that will be labeled
  # @param [Police::DataFlow::Label] label the label to be applied to the
  #     object
  # @return [BasicObject] either the given piece of data, or a proxy that
  #     should be used instead of it
  def self.label(data, label)
    label_set = data.__police_labels__
    if label_set.nil?
      proxied = data
      label_set = {}
    else
      proxied = data.__police_proxied__
    end

    if Police::DataFlow::Labeling.add_label_to_set label, label_set
      data = Police::DataFlow::Proxying.proxy proxied, label_set
    end
    data
  end

  # All the labels attached to a piece of data.
  #
  # @param [Object] data the data whose labels are queried
  # @return [Array<Police::DataFlow::Label>] all the labels attached to the
  #     data
  def self.labels(data)
    return [] unless label_set = data.__police_labels__
    return label_set.first.last.keys if label_set.length == 1

    labels = []
    label_set.each { |label_key, label_hash| labels.concat label_hash.keys }
    labels
  end

  # The actual class of a proxy object.
  #
  # This is necessary because the class method for a proxy object must return
  # the proxied object's class.
  #
  # @private
  # This is intended to help testing the proxying code. It should not be used
  # by client code.
  #
  # @param [BasicObject] data a proxy returned by {Police::DataFlow#label}
  # @return [Class] a subclass of {Police::DataFlow::ProxyBase}, or nil if the
  #    given object is not a proxy
  def self.proxy_class(data)
    if data.__police_labels__.nil?
      nil
    else
      data.__police_class__
    end
  end

# Label algebra.
module Labeling
  # Adds a label to the set of labels held by an object's proxy.
  #
  # @param [Police::DataFlow::Label] label the label to be added to the set
  # @param [Hash<Integer,Hash<Police::DataFlow::Label,Boolean>>] label_set the
  #     set of all labels that will be held by the object's proxy
  # @return [Boolean] false if the set already had a label of the same type, so
  #     the proxy holding the set can still be used; true if the set had to be
  #     expanded, so a new proxy is needed
  def self.add_label_to_set(label, label_set)
    label_class = label.class
    label_key = label_class.__id__
    if label_set.has_key? label_key
      label_set[label_key][label] = true
      return false
    end

    label_entry = { label => true }
    label_set[label_key] = label_entry
    true
  end
end  # namespace Police::DataFlow::Labeling

end  # namespace Police::DataFlow

end  # namespace Police
