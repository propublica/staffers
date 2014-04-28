desc 'Loads environment'
task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require './config/environment'
end

load 'data/load.rake'

task create_indexes: :environment do
  [Quarter, Staffer, Title, Office, Position].each do |klass|
    klass.create_indexes
    puts "Created indexes for #{klass}."
  end
end