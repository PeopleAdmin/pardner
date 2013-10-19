require 'delegate'
require 'commit'
require 'issue_key'

class AugmentedCommit < DelegateClass(Commit)
  def issues
    detected_issues
  end

  def detected_issues
    @detected_issues ||= __getobj__.message.
      scan(/(PA)[-\s_]*(\d+)/i).
      map{|parts| IssueKey.new(*parts)}.uniq.sort
  end

  def suppressed_issues
    @suppressed_issues ||= Set.new
  end

  def added_issues
    @added_issues ||= Set.new
  end
end
