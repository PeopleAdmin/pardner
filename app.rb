require 'rubygems'
require 'bundler'
Bundler.require

get '/' do
  "<a href='/pending/production/master'>Master</a><br>
  <a href='/pending/production/release'>Release</a>"
end

get '/pending/:from/:to' do
  @commits = pending params[:from], params[:to]
  erb :pending
end


private

class Commit
  attr_accessor :sha, :message, :parents

  def self.parse section
    lines = section.split "\n"
    info = lines.each_with_object({}) do |line, store|
      parts = line.split '=', 2
      store[parts[0]] = parts[1]
    end
    new.tap do |commit|
      commit.sha = lines[0]
      commit.parents = lines[1].split(' ')
      commit.message = lines[2..-1].join("\n")
    end
  end

  def parents
    @parents ||= []
  end

  def to_s
    sha
  end

  def subject
    @subject ||= message.split("\n").first
  end
end

def pending from, to
  command = "git log --format='%H%n%P%nMESSAGE=%B@END@' --first-parent origin/#{from}..origin/#{to}"
  output = run_shell command
  output.split("@END@").map {|section| Commit.parse(section.strip.chomp)}
end

def run_shell command
  out = ""
  err = ""
  result = Open4::popen4(command) do |pid, stdin, stdout, stderr|
    out << stdout.read.strip
    err << stderr.read.strip
  end
  if result.exitstatus == 0
    out
  else
    raise err
  end
end
