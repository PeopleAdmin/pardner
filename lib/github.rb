require 'commit'

class Github
  def initialize(user)
    @user = user
  end

  def changes(repo, base, target)
    client.compare repo, base, target
  end

  def tags(repo)
    client.tags repo
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @user.github_token)
  end
end

Octokit.auto_paginate = true
