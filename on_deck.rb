require './commit.rb'

class OnDeck

  def pending from, to
    command = "git log --format='%H%n%P%nMESSAGE=%B@END@' --first-parent origin/#{from}..origin/#{to}"
    output = run_shell command
    output.split("@END@").map {|section| parse_cli_commit(section.strip.chomp)}
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
      out
    else
      raise err
    end
  end

  def parse_cli_commit(section)
    lines = section.split "\n"
    info = lines.each_with_object({}) do |line, store|
      parts = line.split '=', 2
      store[parts[0]] = parts[1]
    end
    Commit.new.tap do |commit|
      commit.sha = lines[0]
      commit.parents = lines[1].split(' ')
      commit.message = lines[2..-1].join("\n")
    end
  end
end
