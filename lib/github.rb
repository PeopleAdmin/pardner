require 'commit'

class Github
  def initialize(user)
    @user = user
  end

  def changes(repo, base, target)
    response = client.compare repo, base, target
    response.commits.map{|details| Commit.new(details)}
  end

  private

  def client
    @client ||= Octokit::Client.new(oauth_token: @user.github_token)
  end
end
