class Commit
  attr_accessor :sha, :message, :parents
  attr_accessor :mainline_parent

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
    @issues ||= message.scan(/PA[-\s_]*(\d+)/i).map{|i| "PA-#{i.first}" }.uniq.sort
  end

  private

  def message_lines
    @message_lines ||= message.split("\n")

  end
end
