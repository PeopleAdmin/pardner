require 'delegate'
require 'commit'
require 'issue_key'

class AugmentedCommit < DelegateClass(Commit)
  def issues
    ((detected_issues + added_issues) - suppressed_issues).sort
  end

  def detected_issues
    @detected_issues ||= Set.new(
      __getobj__.message.
        scan(/(PA)[-\s_]*(\d+)/i).
        map{|parts| IssueKey.new(*parts)}
    )
  end

  def suppress(issues)
    return unless issues
    suppressed_issues.merge issues.map{|i| IssueKey.parse(i)}
  end

  def addend(issues)
    return unless issues
    added_issues.merge issues.map{|i| IssueKey.parse(i)}
  end

  def suppressed_issues
    @suppressed_issues ||= Set.new
  end

  def added_issues
    @added_issues ||= Set.new
  end
end
