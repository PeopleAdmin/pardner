require 'issue_key'

describe IssueKey do
  it "can be created from a prefix and a numeric string" do
    key = IssueKey.new("IK", "12345")
    key.prefix.should == "IK"
    key.number.should == 12345
  end

  it "can be created from a formatted key" do
    key = IssueKey.parse("IK-12345")
    key.prefix.should == "IK"
    key.number.should == 12345
  end

  specify "#to_s returns the formatted key" do
    key = IssueKey.new("IK", "12345")
    key.to_s.should == "IK-12345"
  end

  describe "sorting" do
    it "based on key before number" do
      keys = %w(PA-1234 IF-99999 IF-1000 PA-923).map{|k| IssueKey.parse(k)}
      keys.sort.map(&:to_s).should == %w[IF-1000 IF-99999 PA-923 PA-1234]
    end
  end
end
