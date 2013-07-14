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

  def commits
    @commits
  end

  private

  def issue_lookup
    @issue_lookup ||= @issues.each_with_object({}) do |issue, lookup|
      lookup[issue["key"]] = issue
    end
  end
end
