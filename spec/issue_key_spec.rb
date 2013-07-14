require 'issue_key'

describe IssueKey do
  it "can be created from a prefix and a numeric string" do
    key = IssueKey.new("IK", "12345")
    key.prefix.should == "IK"
    key.number.should == 12345
  end

  specify "#to_s returns the formatted key" do
    key = IssueKey.new("IK", "12345")
    key.to_s.should == "IK-12345"
  end
end
