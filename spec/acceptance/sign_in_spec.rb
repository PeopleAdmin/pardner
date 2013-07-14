require './app.rb'
require 'rack/test'

set :environment, :test

describe 'sign in' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before :each do
    OmniAuth.config.test_mode = true
  end

  specify "home page presents user with login link" do
    get '/'
    last_response.body.should include("Sign in via Github")
  end
end
