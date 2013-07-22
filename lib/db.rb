require 'user'
require 'mongo'

class DB
  def initialize(mongo_url = nil)
    @mongo_url = mongo_url
  end

  def find_user_by_id(id)
    user_data = users.find_one "_id" => BSON::ObjectId(id)
    User.new user_data
  end

  def find_user_by_github_id(github_uid)
    user_data = users.find_one "github.uid" => github_uid
    return nil unless user_data
    User.new user_data
  end

  def find_or_create_user_by_github_auth(auth_data)
    uid = auth_data["uid"]
    raise "Expected auth_data to contain a uid" unless uid
    users.update({"github.uid" => uid}, {"$set" => {"github" => auth_data}}, {upsert: true})
    find_user_by_github_id uid
    #db.users2.ensureIndex({'github.uid': 1})
  end

  def update_user_jira_auth(user, auth_data)
    scrub_jira_auth_data auth_data
    users.update({"_id" => BSON::ObjectId(user.id)}, {"$set" => {"jira" => auth_data}})
    find_user_by_id user.id
  end


  def suppress_issue(repo, commit, issue)
    # append issue to list of issues. store other data?
    commits.update({"repo" => repo, "commit" => commit},
                   {"$push" => {"suppressed_issues" => issue} },
                   {upsert: true})
  end

  def users
    connection["users"]
  end

  def commits
    connection["commits"]
  end

  def reset_db!
    raise "Resetting the database is not supported in production." if env == "production"
    connection.collections.each {|c| connection.drop_collection(c.name)}
  end

  private

  def env
    @env ||= ENV['RACK_ENV'] || 'development'
  end

  def connection
    @connection ||=
      begin
        if @mongo_url
          db_name = @mongo_url[%r{/([^/\?]+)(\?|$)}, 1]
          client = Mongo::MongoClient.from_uri(@mongo_url)
          client.db db_name
        else
          Mongo::MongoClient.new.db("pardner_#{env}")
        end
      end
  end

  # OmniAuth-JIRA stores an OAuth::AccessToken in the hash. We don't want
  # to try and serialize it into the db.
  def scrub_jira_auth_data(auth_data)
    extra = auth_data && auth_data["extra"]
    extra.delete("access_token") if extra
  end
end
