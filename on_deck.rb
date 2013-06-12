require './commit.rb'

class OnDeck

  def initialize(options = {})
    @options = options
  end

  def pending from, to
    command = "git log --format='%H%n%P%nMESSAGE=%B@END@' --first-parent origin/#{from}..origin/#{to}"
    output = run_shell command
    output.split("@END@").map {|section| parse_cli_commit(section.strip.chomp)}
  end

  def pending_gh from, to
    response = github.compare ENV['GH_REPO'], from, to
    all_commits = response.commits.map{|c| parse_gh_commit c}
    # 'to' must be a sha
    first_parents all_commits, to
  end

  def github
    @github ||= Octokit::Client.new(oauth_token: @options[:github_token])
  end



  def first_parents commits, start_sha
    known_commits = commits.each_with_object({}) {|c, h| h[c.sha] = c}
    remaining_shas = [start_sha]
    firsts = []
    while commit_sha = remaining_shas.pop
      commit = known_commits[commit_sha]
      next unless commit
      firsts.push commit
      first_parent = commit.parents.first
      remaining_shas.push commit.parents.first if known_commits.has_key?(first_parent)
    end
    firsts
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

  def parse_gh_commit(gh_commit)
    Commit.new.tap do |commit|
      commit.sha = gh_commit.sha
      commit.parents = gh_commit.parents.map &:sha
      commit.message = gh_commit.commit.message
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
