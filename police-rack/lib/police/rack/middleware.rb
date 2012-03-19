module Police

module Rack

# Rack middleware that labels the HTTP input with UnsafeString.
class Middleware
  def initialize(app, options = {})
    @app = app
    @unsafe_string = Police::Labels::UnsafeString.new
    @unsafe_stream = Police::Labels::UnsafeStream.new @unsafe_string
  end
  
  def call(env)
    label_env env
    @app.call env
    # TODO(pwnall): filter output
  end
  
  def label_env(env)
    env['rack.input'] = Police::DataFlow.label env['rack.input'], @unsafe_stream
    env['QUERY_STRING'] = Police::DataFlow.label env['QUERY_STRING'],
        @unsafe_string
  end
end  # class Police::Rack::Middleware
  
end  # class Police::Rack

end  # class Police
