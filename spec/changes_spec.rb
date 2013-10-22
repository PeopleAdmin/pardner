require 'web/changes_input'
require 'web/changes_output'
require 'commit'

describe ChangesInput do
  let(:input) {
    ChangesInput.new(
      org: "exampleorg",
      repo: "myrepo",
      base: "production",
      target: "master",
    )
  }

  specify "#repo combines organization and repository parameters" do
    input.repo.should == "exampleorg/myrepo"
  end
end

describe ChangesOutput do
  let(:issues){
    [
      {"key" => "PA-1234",  "fields" => {"summary" => "Things broke"}},
      {"key" => "IF-99999", "fields" => {"summary" => "Things are slow"}},
      {"key" => "IF-1000",  "fields" => {"summary" => "Doesn't work"}},
      {"key" => "PA-923",   "fields" => {"summary" => "Add a button"}}
    ]
  }
 
  let(:input) { nil }
  let(:output) {
    ChangesOutput.new(input, nil ,commits, issues)
  }

  # Scenarios to cover:
  # non-merge commit on mainline (A)
  # merge commits started from mainline commit (C)
  # merge commits started from an unincluded commit (G, I)
  # merge commits started from a commit in branch already merged (E)
  #
  #  A
  #  |
  #  B
  #  |\
  #  | C
  #  |/
  #  D
  #  |\
  #  | E
  #  | |
  #  F |
  #  |\|
  #  | G
  #  | |
  #  H I
  #  | |
  #  J K

  let(:commits) {
    all = []
    all << commit('K', [])
    all << commit('J', [])
    all << commit('I', ['K'])
    all << commit('H', ['J'])
    all << commit('G', ['I'])
    all << commit('F', ['H', 'G'])
    all << commit('E', ['G'])
    all << commit('D', ['F', 'E'])
    all << commit('C', ['D'])
    all << commit('B', ['D', 'C'])
    all << commit('A', ['B'])
    all
  }

  describe "#mainline_commits" do
    it "is a list of sorted commits (newest first) from the mainline" do
      output.mainline_commits.map(&:sha).should == %w(A B D F H J)
    end

    context "when there are no commits in the changeset" do
      let (:commits) { [] }
      it "is an empty list when no commits provided" do
        output.mainline_commits.should == []
      end
    end
  end

  describe "#contributing_commits" do
    it "returns an empty list for non-merge commits" do
      output.contributing_commits("A").map(&:sha).should == []
      output.contributing_commits("C").map(&:sha).should == []
      output.contributing_commits("E").map(&:sha).should == []
      output.contributing_commits("G").map(&:sha).should == []
      output.contributing_commits("H").map(&:sha).should == []
      output.contributing_commits("I").map(&:sha).should == []
      output.contributing_commits("J").map(&:sha).should == []
      output.contributing_commits("K").map(&:sha).should == []
      output.contributing_commits("L").map(&:sha).should == []
    end

    it "returns commits brought in for first time by a mineline merge" do
      output.contributing_commits("B").map(&:sha).should == %w(C)
    end

    it "returns only commits not already merged into mainline by previous commit" do
      output.contributing_commits("D").map(&:sha).should == %w(E)
    end

    it "returns a list of commits that were merged into given mainline commit" do
      output.contributing_commits("F").map(&:sha).should == %w(G I K)
    end
  end

  describe "#issue_keys" do
    it "is a sorted list of the issue keys" do
      output.issue_keys.should == %w[IF-1000 IF-99999 PA-923 PA-1234]
    end
  end

  describe "#issue" do
    it "retrieves the details for an issue, given its key" do
      output.issue("IF-99999")["fields"]["summary"].should == "Things are slow"
    end
  end

  describe "Determining status" do
    let(:issues) {
      [
        {"key" => "PA-1234",  "fields" => {"status" => {"name" => "Open"}}},
        {"key" => "PA-5678",  "fields" => {"status" => {"name" => "QA Verified"}}},
        {"key" => "PA-9876",  "fields" => {"status" => {"name" => "Closed"}}},
      ]
    }

    describe "#issue_status" do
      it "returns :verified when the issue is Closed in JIRA" do
        output.issue_status("PA-9876").should == :verified
      end
      it "returns :verified when the issue is QA Verified in JIRA" do
        output.issue_status("PA-5678").should == :verified
      end
      it "returns :unverified when the issue is still open in JIRA" do
        output.issue_status("PA-1234").should == :unverified
      end
      it "raises when the issue when the issue is unknown" do
        expect { output.issue_status("XX-9999") }.to raise_error /unknown issue/
      end
    end

    describe "#commit_status" do
      it "returns :unverified if it has no related issues" do
        commit = double("AugmentedCommit", issues: [])
        output.commit_status(commit).should == :unverified
      end
      it "returns :verified if all related issues are verified" do
        commit = double("AugmentedCommit", issues: ["PA-5678", "PA-9876"])
        output.commit_status(commit).should == :verified
      end
      it "returns :unverified if any related issue is unverified" do
        commit = double("AugmentedCommit", issues: ["PA-1234", "PA-5678"])
        output.commit_status(commit).should == :unverified
      end
    end
  end


  private

  def commit sha, parent_shas
    Commit.new({
      sha: sha,
      parents: parent_shas.map{|sha| {sha: sha}}
    })
  end
end
