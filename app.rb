require 'rubygems'
require 'bundler'
Bundler.require
require './commit.rb'
require './on_deck.rb'

get '/' do
  "<a href='/pending/production/master'>Master</a><br>
  <a href='/pending/production/release'>Release</a>"
end

get '/pending/:from/:to' do
  @commits = ondeck.pending_gh params[:from], params[:to]
  erb :pending
end


private

def ondeck
  @ondeck ||= OnDeck.new
end
