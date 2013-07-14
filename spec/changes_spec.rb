require 'web/changes_input'
require 'web/changes_output'

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
  let(:output){ ChangesOutput.new(nil, nil, issues) }

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
end
