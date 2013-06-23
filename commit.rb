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
    format_issues issue_numbers
  end

  def issue_numbers
    @issue_numbers ||= message.scan(/PA[-\s_]*(\d+)/i).
      map{|i| i.first.to_i}
  end

  def all_issues
    format_issues issue_numbers + contributing_commits.flat_map(&:issue_numbers)
  end

  private

  def format_issues issue_list
    issue_list.uniq.sort.map{|i| "PA-#{i}" }
  end

  def message_lines
    @message_lines ||= message.split("\n")

  end
end
