require 'augmented_commit'

describe AugmentedCommit do
  let(:commit_data) do
    {
      sha: "abcdef1234567890",
      commit: {
        message: "Make a change\n\nBe positive.\nLook ahead."
      },
      parents: [
      ]
    }
  end

  let(:commit) {
    AugmentedCommit.new(Commit.new commit_data)
  }


  describe "#issues" do
    it "an ordered, unique list of issues detected or added, except those suppressed" do
      commit.stub(:detected_issues) { Set.new([IssueKey.parse("PA-1234"), IssueKey.parse("PA-4444")])}
      commit.stub(:suppressed_issues) { Set.new([IssueKey.parse("PA-4444")])}
      commit.stub(:added_issues) { Set.new([IssueKey.parse("PA-555")])}

      commit.issues.map(&:to_s).should =~ %w(PA-555 PA-1234)
    end
  end

  describe "#detected_issues" do
    it "a set of JIRA numbers found within the commit message" do
      commit_data[:commit][:message] = "Fixes PA-1234 and pa  923

      With a little bit of PA4563 and pa_34536. Does not address 781.
      The next commit should completely fix PA-34536"

      commit.detected_issues.map(&:to_s).should =~ %w(PA-923 PA-1234 PA-4563 PA-34536)
    end

    it "has special-case logic to avoid identifying PA7 as a JIRA number" do
      commit_data[:commit][:message] = "Fixes PA-7, PA-77, and PA-8 in PA7"
      commit.detected_issues.map(&:to_s).should =~ %w(PA-77 PA-8)
    end
  end
end
