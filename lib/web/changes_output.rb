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

  def issues
    @issues
  end

  def commits
    @commits
  end
end
