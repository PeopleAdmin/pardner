class Commit
  attr_accessor :sha, :message, :parents

  def parents
    @parents ||= []
  end

  def to_s
    sha
  end

  def subject
    @subject ||= message.split("\n").first
  end
end
