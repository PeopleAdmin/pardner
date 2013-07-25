require './user.rb'
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

  def users
    connection["users"]
  end

  private

  def connection
    @connection ||=
      begin
        if @mongo_url
          db_name = @mongo_url[%r{/([^/\?]+)(\?|$)}, 1]
          client = Mongo::MongoClient.from_uri(@mongo_url)
          client.db db_name
        else
          Mongo::MongoClient.new.db("test")
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
