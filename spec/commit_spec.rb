require 'commit'

describe Commit do
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
    Commit.new commit_data
  }

  describe "basic attributes" do
    specify "sha" do
      commit.sha.should == "abcdef1234567890"
    end
    specify "short_sha is only first 10 characters" do
      commit.short_sha.should == "abcdef1234"
    end
    specify "subject is only first line of message" do
      commit.subject.should == "Make a change"
    end
    specify "body is the message without the first line" do
      commit.body.should == "Be positive.\nLook ahead."
    end
  end

  describe "#merge?" do
    it "is false when the commit has less than 2 parents" do
      commit.merge?.should be_false
    end

    it "is true when the commit has 2 or more parents" do
      commit_data[:parents] = [{},{}]
      commit.merge?.should be_true
    end
  end
end
