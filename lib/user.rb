class User
  def initialize(data)
    @data = data
  end

  def id
    object_id = get "_id"
    object_id.to_s if object_id
  end

  def github_uid
    get "github", "uid"
  end

  def name
    get "github", "info", "name"
  end

  def github_username
    get "github", "info", "nickname"
  end

  def github_token
    get "github", "credentials", "token"
  end

  def github_authenticated?
    !!github_token
  end

  def jira_username
    get "jira", "info", "name"
  end

  def jira_authenticated?
    !!jira_token
  end

  def jira_token
    get "jira", "credentials", "token"
  end

  def jira_secret
    get "jira", "credentials", "secret"
  end

  private

  def get *keys
    keys.reduce(@data) do |data, key|
      data[key] if data
    end
  end
end
