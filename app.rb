require 'rubygems'
require 'bundler'
Bundler.require

get '/' do
  command = "git log --oneline --first-parent origin/production..origin/master"
  run_shell command
end


private

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
