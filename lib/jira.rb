require 'oauth'

class Jira
  def initialize(consumer, user)
    @consumer = consumer
    @user = user
  end

  def issue_details(issues)
    return [] if issues.nil? || issues.empty?
    response = request "/rest/api/2/search?jql=id%20in%20(#{Array(issues).join(',')})&fields=status,summary,labels"
    response["issues"] || []
  end


  private

  def client
    @client ||=
      begin
        OAuth::AccessToken.new(@consumer, @user.jira_token, @user.jira_secret)
      end
  end

  def request url
    response = client.get(url, {'Accept' => 'application/json'}).body
    MultiJson.decode(response)
  end
end

