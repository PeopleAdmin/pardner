class Commit
  attr_accessor :sha, :message, :parents
  attr_accessor :mainline_parent
  attr_accessor :contributing_commits

  def parents
    @parents ||= []
  end

  def contributing_commits
    @contributing_commits ||= []
  end

  def short_sha
    sha[0..9]
  end

  def to_s
    sha
  end

  def subject
    @subject ||= message_lines.first
  end

  def body
    @body ||= message_lines[1..-1].join("\n")
  end

  def issues
    self.class.format_issues issue_numbers
  end

  def issue_numbers
    @issue_numbers ||= message.scan(/PA[-\s_]*(\d+)/i).
      map{|i| i.first.to_i}
  end

  def all_issue_numbers
    issue_numbers + contributing_commits.flat_map(&:issue_numbers)
  end

  def all_issues
    self.class.format_issues all_issue_numbers
  end

  def self.format_issues issue_numbers
    issue_numbers.uniq.sort.map{|i| "PA-#{i}" }
  end

  def self.issues commits
    format_issues commits.flat_map(&:all_issue_numbers)
  end

  private

  def message_lines
    @message_lines ||= message.split("\n")

  end
end
