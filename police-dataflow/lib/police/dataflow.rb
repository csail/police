module Police

# Data flow labels "track" data as it is processed in a complex system.
module DataFlow
  # Attaches a label to a piece of data.
  #
  # @param [Object] data the data that will be labeled
  # @param [Police::DataFlow::Label] label the label to be applied to the object
  # @return [Object] either the given piece of data, or a proxy that should be
  #     used instead of it
  def label(data, label)

  end
  
  # All the labels attached to a piece of data.
  #
  # @param [Object] data the data whose labels are queried
  # @return [Array<Police::DataFlow::Label>] all the labels attached to the data
  def labels(data)
    
  end
end  # namespace Police::DataFlow

end  # namespace Police


require 'police/dataflow/label.rb'
require 'police/dataflow/labeler.rb'
require 'police/dataflow/proxy_base.rb'
require 'police/dataflow/proxying.rb'
