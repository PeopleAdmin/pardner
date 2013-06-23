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
    grouped_commits all_commits, all_commits.last.sha
  end

  def status identifier
    jira_request "/rest/api/2/issue/#{params[:identifier]}?expand=changelog"
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

  def grouped_commits commits, start_sha
    known_commits = commits.each_with_object({}) {|c, h| h[c.sha] = c}
    mainline = first_parents commits, start_sha
    mainline.each do |mainline_parent|
      # traverse all parents except first
      # record mainline parent
      remaining_shas = mainline_parent.parents[1..-1] || []
      while commit_sha = remaining_shas.pop
        commit = known_commits[commit_sha]
        next unless commit
        next if mainline.include? commit
        commit.mainline_parent = mainline_parent
        remaining_shas += commit.parents
      end
    end
    mainline.each do |mainline_parent|
      mainline_parent.contributing_commits = commits.select{|c| c.mainline_parent == mainline_parent}
    end
  end

  private

  def jira_request url
    response = jira.get(url, {'Accept' => 'application/json'}).body
    Hashie::Mash.new(MultiJson.decode(response))
  end

  def jira
    @jira ||=
      begin
        OAuth::AccessToken.new(@options[:jira_consumer],
                               @options[:jira_token], @options[:jira_secret])
      end
  end

  def github
    @github ||= Octokit::Client.new(oauth_token: @options[:github_token])
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
