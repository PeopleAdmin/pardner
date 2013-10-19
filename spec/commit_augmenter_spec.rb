require 'commit_augmenter'

describe CommitAugmenter do
  describe "#augment" do
    let(:store) { double("store") }
    let(:repo) { "example/repo" }
    let(:augmenter) { CommitAugmenter.new(store, repo) }

    it "returns an AugmentedCommit for each Commit" do
      store.stub(:commit_info) { {} }
      commits = build_commits "1234", "5678"
      augmented_commits = augmenter.augment(commits)
      augmented_commits.count.should == commits.count
      augmented_commits.each{|ac| ac.should be_an_instance_of(AugmentedCommit)}
    end

    it "attaches the list of issues suppressed for each commit" do
      commits = build_commits "a1a2a34", "b5b6b78"
      store.stub(:commit_info) do
        {
          "a1a2a34" => {"suppressed_issues" => ["EX-3333"]},
          "b5b6b78" => {"suppressed_issues" => ["EX-2222", "EX-4444"]}
        }
      end

      augmented = augmenter.augment(commits)
      augmented[0].suppressed_issues.should include("EX-3333")
      augmented[0].suppressed_issues.should_not include("EX-2222")

      augmented[1].suppressed_issues.should include("EX-2222")
      augmented[1].suppressed_issues.should include("EX-4444")
      augmented[1].suppressed_issues.should_not include("EX-3333")
    end

    it "attaches the list of issues manually added for each commit" do
      commits = build_commits "a1a2a34", "b5b6b78"
      store.stub(:commit_info) do
        {
          "a1a2a34" => {"added_issues" => ["EX-3333"]},
          "b5b6b78" => {"added_issues" => ["EX-2222", "EX-4444"]}
        }
      end

      augmented = augmenter.augment(commits)
      augmented[0].added_issues.should include("EX-3333")
      augmented[0].added_issues.should_not include("EX-2222")

      augmented[1].added_issues.should include("EX-2222")
      augmented[1].added_issues.should include("EX-4444")
      augmented[1].added_issues.should_not include("EX-3333")
    end
  end

  def build_commits(*shas)
    shas.map{|sha| Commit.new(sha: sha)}
  end
end
