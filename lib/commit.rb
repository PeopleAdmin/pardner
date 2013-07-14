class Commit
  def initialize(data)
    @data = data
  end

  def sha; @data[:sha]; end

  def short_sha
    sha[0..9]
  end

  def message
    @data[:commit][:message]
  end

  def subject
    @subject ||= message_lines.first
  end

  def body
    @body ||= message_lines[1..-1].join("\n").lstrip
  end

  def merge?
    @data[:parents].length > 1
  end


  private

  def message_lines
    @message_lines ||= message.split("\n")
  end
end
