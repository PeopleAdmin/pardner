class Commit
  attr_accessor :sha, :message, :parents
  attr_accessor :mainline_parent
  attr_accessor :contributing_commits

  def parents
    @parents ||= []
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
    @issues ||= message.scan(/PA[-\s_]*(\d+)/i).
      map{|i| i.first.to_i}.
      uniq.sort.
      map{|i| "PA-#{i}" }
  end

  private

  def message_lines
    @message_lines ||= message.split("\n")

  end
end
