require 'rubygems'
require 'bundler'
Bundler.require
require './db.rb'
require './commit.rb'
require './on_deck.rb'

load '.settings' if File.exists? '.settings'

if ENV['GITHUB_CLIENT_ID']
  set :github_client_id, ENV['GITHUB_CLIENT_ID']
  set :github_client_secret, ENV['GITHUB_CLIENT_SECRET']
  set :jira_consumer_key, ENV['JIRA_CONSUMER_KEY']
  set :jira_rsa_key, OpenSSL::PKey::RSA.new(ENV['JIRA_RSA_PEM'])
  set :jira_url, ENV['JIRA_URL']
  set :session_secret, ENV['SESSION_SECRET']
end

use Rack::Session::Cookie, key: 'app.session',
                           path: '/',
                           expire_after: 60*60*24*60,
                           secret: settings.session_secret

use OmniAuth::Builder do
  provider :github, settings.github_client_id, settings.github_client_secret, scope: "repo"
  provider :JIRA,
    settings.jira_consumer_key,
    settings.jira_rsa_key,
    :client_options => { :site => settings.jira_url }
end

def db
  @db ||= DB.new(ENV['MONGOLAB_URI'])
end

PUBLIC_URLS = ['/', '/logout', '/auth/failure']

before do
  identify_user
  authenticate_with_github! if require_github_auth?
  authenticate_with_jira! if require_jira_auth?
end

helpers do
  def current_user
    @current_user
  end

  def logged_in
    !!current_user
  end

  def identify_user
    return unless session["user_id"]
    @current_user = db.find_user_by_id session["user_id"]
  end

  def require_github_auth?
    access_without_github_auth = PUBLIC_URLS +
      ['/auth/github', '/auth/github/callback']
    !access_without_github_auth.include? request.path_info
  end

  def require_jira_auth?
    access_without_jira_auth = PUBLIC_URLS +
      ['/auth/github', '/auth/github/callback', '/auth/JIRA', '/auth/JIRA/callback']
    !access_without_jira_auth.include? request.path_info
  end

  def github_authenticated?
    current_user && current_user.github_authenticated?
  end

  def jira_authenticated?
    current_user && current_user.jira_authenticated?
  end

  def authenticate_with_github!
    redirect '/auth/github' unless github_authenticated?
  end

  def authenticate_with_jira!
    redirect '/auth/JIRA' unless jira_authenticated?
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end
end


get '/' do
  erb :index
end

get '/:org/:repo/pending/:from/:to' do
  repo = "#{params[:org]}/#{params[:repo]}"
  @commits = ondeck.pending repo, params[:from], params[:to]
  erb :pending
end

get '/status/:identifier' do
  content_type :json
  MultiJson.dump(ondeck.status(params[:identifier]), pretty: true)
end

get '/auth/github/callback' do
  @user = db.find_or_create_user_by_github_auth request.env['omniauth.auth']
  session["user_id"] = @user.id
  redirect "/"
end

get '/auth/JIRA/callback' do
  db.update_user_jira_auth current_user, request.env['omniauth.auth']
  redirect "/"
end

# Probably need these....
get '/auth/failure' do
  content_type 'text/plain'
  "Failed to authenticate: #{params[:message]}"
end

get '/logout' do
  session["user_id"] = nil
  redirect '/'
end

private

def ondeck
  @ondeck ||= OnDeck.new current_user, jira_consumer: jira_consumer
end

def jira_consumer
  @consumer ||= OAuth::Consumer.new(
    settings.jira_consumer_key, settings.jira_rsa_key,
    {
      :site => settings.jira_url,
      :signature_method => 'RSA-SHA1',
      :scheme => :header,
    }).tap {|c| c.http.set_debug_output($stderr) }
end
