require 'commit_augmenter'

describe CommitAugmenter do
  describe "#augment" do
    let(:augmenter) { CommitAugmenter.new(nil) }
    it "returns an AugmentedCommit for each Commit" do
      commits = [:foo, :bar]
      augmented_commits = augmenter.augment(commits)
      augmented_commits.count.should == commits.count
      augmented_commits.each{|ac| ac.should be_an_instance_of(AugmentedCommit)}
    end
  end
end
