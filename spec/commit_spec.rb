require './commit.rb'

describe Commit do
  let(:commit) {
    commit = Commit.new
    commit.message = "Fixes PA-1234 and pa  923

      With a little bit of PA4563 and pa_34536. Does not address 781."
    commit
  }
  describe "#issues" do
    it "ordered list of all JIRA numbers within the commit message" do

      commit.issues.should == %w(PA-923 PA-1234 PA-4563 PA-34536)
    end
  end

  describe "#all_issues" do
    it "ordered list of JIRA numbers referenced by all contributing commits" do
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA-3390"}
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA804"}
      commit.contributing_commits << Commit.new.tap{|c| c.message = "Fixed PA 5000 PA-60000"}

      commit.all_issues.should == %w(PA-804 PA-923 PA-1234 PA-3390 PA-4563 PA-5000 PA-34536 PA-60000)
    end
  end
end

