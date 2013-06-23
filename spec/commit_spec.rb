require './commit.rb'

describe Commit do
  describe "#issues" do
    it "ordered list of all JIRA numbers within the commit message" do
      commit = Commit.new
      commit.message = "Fixes PA-1234 and pa  923

      With a little bit of PA4563 and pa_34536. Does not address 781."

      commit.issues.should == %w(PA-923 PA-1234 PA-4563 PA-34536)
    end
  end
end

