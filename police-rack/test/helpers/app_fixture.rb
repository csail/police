class AppFixture
  def call(env)
    [200, {'Content-Type' => 'text/html'}, [""]]
  end
  
  def render(env)
    <<END_HTML
<!doctype html>
<html>
  <body>
    <p>Hello #{env['rack.params']['name']}</p>
  </boy>
</html>
END_HTML
  end
  
  def self.app
    Rack::Builder.new do
      use Police::Rack::Middleware
      run AppFixture.new
    end
  end
end
