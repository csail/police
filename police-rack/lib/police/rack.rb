module Police

# Rack middleware that labels HTTP input and filters the application output.
module Rack
end  # namespace Police::Rack

end  # namespace Police

require 'police/dataflow'
require 'police/labels'
require 'police/rack/middleware.rb'
