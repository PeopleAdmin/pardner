require 'db'

describe DB do
  let(:repo) { "example/repo" }
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
      commit = 'a1b2c3d4'
      issue = 'IS-9876'

      db.suppress_issue repo, commit, issue

      commit = db.commits(repo).find_one({"_id" => commit})
      commit.should_not be_nil
      commit["suppressed_issues"].should == ["IS-9876"]
    end
  end

  describe "#add_issue" do
    it "stores the issue to assign to a given commit" do
      commit = 'a1b2c3d4'
      issue = 'IS-9876'

      db.add_issue repo, commit, issue

      commit = db.commits(repo).find_one({"_id" => commit})
      commit.should_not be_nil
      commit["added_issues"].should == ["IS-9876"]
    end
  end

  describe "#commit_info" do
    before do
      db.add_issue repo, "d1d2d3", "IS-9999"
      db.add_issue repo, "a1a2a3", "IS-1111"
      db.add_issue repo, "a1a2a3", "IS-2222"
      db.add_issue repo, "b1b2b3", "IS-3333"
      db.suppress_issue repo, "b1b2b3", "IS-5555"
    end
    let(:returned) { db.commit_info repo, ["a1a2a3", "b1b2b3", "c1c2c3"] }

    it "returns added issues per commit" do
      returned["a1a2a3"]["added_issues"].should == ["IS-1111", "IS-2222"]
      returned["b1b2b3"]["added_issues"].should == ["IS-3333"]
    end
    it "returns suppressed issues per commit" do
      returned["b1b2b3"]["suppressed_issues"].should == ["IS-5555"]
      returned["a1a2a3"]["suppressed_issues"].should be_nil
    end

    it "doesn't return info for commits not requested" do
      returned["d1d2d3"].should be_nil
    end

    it "doesn't return info for commits without any additional data" do
      returned["c1c2c3"].should be_nil
    end
  end
end
