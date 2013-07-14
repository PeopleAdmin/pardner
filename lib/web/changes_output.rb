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
    []
  end

  def commits
    []
  end
end
