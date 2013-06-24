require 'rubygems'
require 'bundler'
Bundler.require
require './commit.rb'
require './on_deck.rb'

load '.settings' if File.exists? '.settings'

if ENV['GITHUB_CLIENT_ID']
  set :github_client_id, ENV['GITHUB_CLIENT_ID']
  set :github_client_secret, ENV['GITHUB_CLIENT_SECRET']
  set :jira_consumer_key, ENV['JIRA_CONSUMER_KEY']
  set :jira_rsa_key, OpenSSL::PKey::RSA.new(ENV['JIRA_RSA_PEM'])
  set :jira_url, ENV['JIRA_URL']
end

use OmniAuth::Builder do
  provider :github, settings.github_client_id, settings.github_client_secret, scope: "repo"
  provider :JIRA,
    settings.jira_consumer_key,
    settings.jira_rsa_key,
    :client_options => { :site => settings.jira_url }
end

PUBLIC_URLS = ['/', '/logout', '/auth/failure',
               '/auth/github', '/auth/github/callback',
               '/auth/JIRA', '/auth/JIRA/callback']


enable :sessions

before do
  protected! unless PUBLIC_URLS.include? request.path_info
end

helpers do
  def github_token
    session["github_token"]
  end

  def jira_token
    session["JIRA_token"]
  end

  def jira_secret
    session["JIRA_secret"]
  end

  def logged_in
    !!github_token
  end

  def jira_confirmed
    !!jira_token
  end

  def protected!
    redirect '/auth/github' unless logged_in
  end
end


get '/' do
  "
  #{ logged_in ? "Github Token #{github_token}" : "<a href='auth/github'>Sign in via Github</a>" }
  <br>
  #{ !jira_confirmed ? "<a href='auth/JIRA'>Confirm JIRA</a>" : "JIRA Token #{jira_token}
  <br>
  <a href='/PeopleAdmin/hr_suite/pending/production/master'>Master</a>
  <br>
  <a href='/PeopleAdmin/hr_suite/pending/production/release'>Release</a>"}"
end

get '/:org/:repo/pending/:from/:to' do
  repo = "#{params[:org]}/#{params[:repo]}"
  @commits = ondeck.pending repo, params[:from], params[:to]
  erb :pending
end

get '/status/:identifier' do
  ondeck.status params[:identifier]
end

get '/auth/:provider/callback' do
  omniauth = request.env['omniauth.auth']
  provider = params[:provider]
  session["#{provider}_token"] = omniauth['credentials']['token']
  if provider == "JIRA"
    session["JIRA_secret"] = omniauth['credentials']['secret']
  end
  redirect "/"
end

# Probably need these....
get '/auth/failure' do
  content_type 'text/plain'
  "Failed to authenticate: #{params[:message]}"
end

get '/logout' do
  session["github_token"] = nil
  session["JIRA_token"] = nil
  redirect '/'
end

private

def ondeck
  @ondeck ||= OnDeck.new github_token: github_token,
    jira_token: jira_token, jira_secret: jira_secret,
    jira_consumer: jira_consumer
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
