require 'jira'

describe Jira do
  describe "#issue_details" do
    it "does not make a web request when passed an empty list of issues" do
      user = double("user")
      user.should_not_receive :jira_token
      Jira.new(nil, user).issue_details([]).should == []
    end
  end

end
