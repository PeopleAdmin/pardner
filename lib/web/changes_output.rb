require 'issue_key'

class ChangesOutput
  def initialize(input, commits, issues)
    @input = input
    @commits = commits
    @issues = issues
  end

  def target
    @input.target
  end

  def base
    @input.base
  end

  def issue_keys
    @keys ||= issue_lookup.keys.map{|k| IssueKey.parse(k)}.sort.map(&:to_s)
  end

  def issue(key)
    issue_lookup[key]
  end

  def contributing_commits(commit_or_sha)
    sha = commit_or_sha.respond_to?(:sha) ? commit_or_sha.sha : commit_or_sha
    contributors_lookup[sha] || []
  end

  def mainline_commits
    @mainlines ||=
      begin
        return [] if @commits.empty?
        remaining_shas = [@commits.last.sha]
        mainlines = []
        while commit_sha = remaining_shas.pop
          commit = commit_lookup[commit_sha]
          next unless commit
          mainlines.push commit
          first_parent = commit.parents.first
          remaining_shas.push commit.parents.first
        end
        mainlines
      end
  end

  private

  def issue_lookup
    @issue_lookup ||= @issues.each_with_object({}) do |issue, lookup|
      lookup[issue["key"]] = issue
    end
  end

  def commit_lookup
    @commit_lookup ||= @commits.each_with_object({}) {|c, h| h[c.sha] = c}
  end

  def contributors_lookup
    @contributors_lookup ||=
      begin
        mainline_merges = {}
        mainline_commits.each do |mainline_commit|
          # traverse all mainline commits except first
          # record mainline merge commit
          remaining_shas = mainline_commit.parents[1..-1] || []
          while commit_sha = remaining_shas.pop
            commit = commit_lookup[commit_sha]
            next unless commit
            next if mainline_commits.include? commit
            mainline_merges[commit.sha] = mainline_commit
            remaining_shas += commit.parents
          end
        end
        lookup = {}
        mainline_commits.each do |mainline_commit|
          lookup[mainline_commit.sha] = @commits.select{|c|
            mainline_merges[c.sha] == mainline_commit
          }.reverse
        end
        lookup
      end
  end
end
