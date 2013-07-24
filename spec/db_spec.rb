require 'db'

describe DB do
  let(:db) { DB.new }

  before do
    ENV['RACK_ENV'] ||= 'test'
    db.reset_db!
  end

  it "connects to test database for tests" do
    db.send(:connection).name.should == "pardner_test"
  end

  describe "#suppress_issue" do
    it "stores the issue to ignore on a given commit" do
      repo = 'example_org/sample_repo'
      commit = 'a1b2c3d4'
      issue = 'IS-9876'

      db.suppress_issue repo, commit, issue

      commit = db.commits(repo).find_one({"_id" => commit})
      commit.should_not be_nil
      commit["suppressed_issues"].should == ["IS-9876"]
    end
  end
end
