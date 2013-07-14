require 'augmented_commit'

class CommitAugmenter
  def initialize(store)
    @store = store
  end

  def augment(commits)
    commits.map{|commit| AugmentedCommit.new(commit)}
  end
end
