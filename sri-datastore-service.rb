require 'sqlite3'
require 'google/cloud/datastore'

# gems:
# sqlite3
# sinatra-contrib

#require 'securerandom'

# $db = SQLite3::Database.new 'db-global-object-ids.sqlite3'

class SystemRecordIdMax

  attr_accessor :id, :organization, :system, :object_type, :id_max

  # Return a Google::Cloud::Datastore::Dataset for the configured dataset.
  # The dataset is used to create, read, update, and delete entity objects.
  def self.dataset
    @dataset ||= Google::Cloud::Datastore.new()

      #project: "dmp-srid-service",
      #keyfile: "srid.json"
      # project: Rails.application.config. database_configuration[Rails.env]["dataset_id"]
#    )
  end

end

# Copyright 2015 Google, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START app]
require "sinatra"
#require "sinatra/json"
require "json"

get "/" do
  "Hello world!"
end

def getobjectspace( organization, system, object_type )
  fkid_object_space = nil
  $db.execute("select rowid from object_space where organization=? and system=? and object_type=?",
              organization, system, object_type ) do |row|
    fkid_object_space = row[0]
  end
  fkid_object_space
end

get "/record" do
  content_type :json
#  guid = SecureRandom.random_bytes(16) # 128 bits of random datan
  nextid = 0
  
  organization = params[:organization]
  system = params[:system]
  object_type = params[:object_type]

  fkid_object_space = getobjectspace(organization, system, object_type)
                          
  if not fkid_object_space then
    $db.transaction do |txn|
      txn.execute("insert into object_space (organization, system, object_type) values(?, ?, ?)",
                  organization, system, object_type)
      fkid_object_space = getobjectspace(organization, system, object_type)
      txn.execute("insert into object_id values (?, ?)", fkid_object_space, 1337)
    end
  end
  
  
  $db.transaction do |txn|
    txn.execute("select object_id from object_id where fkid_object_space=#{fkid_object_space}") do |row|
      nextid = row[0].to_i + 1
    end
    txn.execute("update object_id set object_id=#{nextid} where fkid_object_space=#{fkid_object_space}")
  end
  resp = {:id => nextid, :fkid => fkid_object_space}
  #  json(  resp, :content_type => :js )
  resp.to_json
#  "{ id = #{nextid}, fkid=#{fkid_object_space} }"
end

# [END app]
