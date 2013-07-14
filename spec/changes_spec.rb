require 'web/changes_input'
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
