require 'rubygems'
require 'bundler'
Bundler.require
require './commit.rb'
require './on_deck.rb'

use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "repo"
  provider :JIRA,
    ENV['JIRA_CONSUMER_KEY'],
    OpenSSL::PKey::RSA.new(IO.read(File.dirname(__FILE__) + "/rsa.pem")),
    :client_options => { :site => ENV['JIRA_URL'] }
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
  #{ jira_confirmed ? "JIRA Token #{jira_token}" : "<a href='auth/JIRA'>Confirm JIRA</a>" }
  <br>
  <a href='/pending/production/master'>Master</a>
  <br>
  <a href='/pending/production/release'>Release</a>"
end

get '/pending/:from/:to' do
  @commits = ondeck.pending_gh params[:from], params[:to]
  erb :pending
end

get '/auth/:provider/callback' do
  omniauth = request.env['omniauth.auth']
  session["#{params[:provider]}_token"] = omniauth['credentials']['token']
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
  @ondeck ||= OnDeck.new github_token: github_token
end
