module Police

# Data flow labels "track" data as it is processed in a complex system.
module DataFlow
end  # namespace Police::DataFlow

end  # namespace Police


require 'police/dataflow/core_extensions.rb'
require 'police/dataflow/gating.rb'
require 'police/dataflow/label.rb'
require 'police/dataflow/labeling.rb'
require 'police/dataflow/proxies.rb'
require 'police/dataflow/proxy_base.rb'
require 'police/dataflow/proxy_numeric.rb'
require 'police/dataflow/proxying.rb'
