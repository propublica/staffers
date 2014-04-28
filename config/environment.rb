require 'sinatra'
require 'mongoid'
require 'mongoid/slug'
require 'safe_yaml'

def config
  @config ||= YAML.safe_load_file File.join(File.dirname(__FILE__), "config.yml")
end

configure do
  Mongoid.configure {|c| c.from_hash config['mongoid']}
  SafeYAML::OPTIONS[:default_mode] = :safe
end

require './models'