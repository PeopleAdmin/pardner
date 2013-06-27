require './commit.rb'

class OnDeck

  def initialize(user, options = {})
    @user = user
    @options = options
  end

  def pending repo, from, to
    response = github.compare repo, from, to
    all_commits = response.commits.map{|c| parse_gh_commit c}
    grouped_commits all_commits, all_commits.last.sha
  end

  def status identifier
    jira_request "/rest/api/2/issue/#{identifier}?expand=changelog"
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
      mainline_parent.contributing_commits = commits.select{|c| c.mainline_parent == mainline_parent}.reverse
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
                               @user.jira_token, @user.jira_secret)
      end
  end

  def github
    @github ||= Octokit::Client.new(oauth_token: @user.github_token)
  end

  def parse_gh_commit(gh_commit)
    Commit.new.tap do |commit|
      commit.sha = gh_commit.sha
      commit.parents = gh_commit.parents.map &:sha
      commit.message = gh_commit.commit.message
    end
  end
end
