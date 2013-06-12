require 'rubygems'
require 'bundler'
Bundler.require
require './commit.rb'
require './on_deck.rb'

use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "repo"
end

PUBLIC_URLS = ['/', '/logout', '/auth/github', '/auth/github/callback', '/auth/failure']


enable :sessions

before do
  protected! unless PUBLIC_URLS.include? request.path_info
end

helpers do
  def github_token
    session["github_token"]
  end

  def logged_in
    !!github_token
  end

  def protected!
    redirect '/auth/github' unless logged_in
  end
end


get '/' do
  "
  <a href='auth/github'>Sign in via Github</a> Current token: #{github_token}
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
  session['github_token'] = omniauth['credentials']['token']
  redirect "/"
end

# Probably need these....
get '/auth/failure' do
  content_type 'text/plain'
  "Failed to authenticate: #{params[:message]}"
end

get '/logout' do
  session["github_token"] = nil
  redirect '/'
end

private

def ondeck
  @ondeck ||= OnDeck.new github_token: github_token
end
