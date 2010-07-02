require 'rubygems'
require 'sinatra'
require 'sunlight'

require 'active_support' 
require 'mongo'
require 'mongo_mapper'

def config
  @config ||= YAML.load_file 'config/config.yml'
end

configure do
  MongoMapper.connection = Mongo::Connection.new config[:database][:hostname]
  MongoMapper.database = config[:database][:database]
end