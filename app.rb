require 'rubygems'
require 'bundler'
Bundler.require

get '/' do
  "<a href='/pending/production/master'>Master</a><br>
  <a href='/pending/production/release'>Release</a>"
end

get '/pending/:from/:to' do
  commits params[:from], params[:to]
end


private

def commits from, to
  command = "git log --oneline --first-parent origin/#{from}..origin/#{to}"
  run_shell command
end

def run_shell command
  out = ""
  err = ""
  result = Open4::popen4(command) do |pid, stdin, stdout, stderr|
    out << stdout.read.strip
    err << stderr.read.strip
  end
  if result.exitstatus == 0
    out.gsub(/\n/, "<br>")
  else
    raise err
  end
end
