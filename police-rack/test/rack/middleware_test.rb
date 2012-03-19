require File.expand_path('../helper.rb', File.dirname(__FILE__))

describe Police::Rack::Middleware do
  def app
    AppFixture.app
  end

  it "doesn't crash" do
    get '/'
    last_response.status.must_equal 200
  end
end
