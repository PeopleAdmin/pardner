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

  describe "#detected_issues" do
    it "an ordered of JIRA numbers within the commit message" do
      commit_data[:commit][:message] = "Fixes PA-1234 and pa  923

      With a little bit of PA4563 and pa_34536. Does not address 781.
      The next commit should completely fix PA-34536"

      commit.detected_issues.map(&:to_s).should == %w(PA-923 PA-1234 PA-4563 PA-34536)
    end
  end

  describe "#issues" do
    pending "all detected issues and added issues, with suppressed issues removed" do
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA-3390"}
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA804"}
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA 5000 PA-60000"}

      commit.all_issues.should == %w(PA-804 PA-923 PA-1234 PA-3390 PA-4563 PA-5000 PA-34536 PA-60000)
    end
  end
end