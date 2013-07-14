class IssueKey
  include Comparable

  attr_reader :prefix, :number

  def initialize(prefix, number)
    @prefix = prefix.upcase
    @number = number.to_i
  end

  def to_s
    "#{@prefix}-#{@number}"
  end

  def inspect
    "#<IssueKey #{to_s}>"
  end

  def <=>(other)
    return nil unless other.is_a?(IssueKey)
    cmp = @prefix <=> other.prefix
    return unless cmp == 0
    @number <=> other.number
  end

  def hash
    @prefix.hash ^ @number.hash
  end

  def eql?(other)
    self.class.equal?(other.class) &&
      @prefix == other.prefix &&
      @number == other.number
  end
end
