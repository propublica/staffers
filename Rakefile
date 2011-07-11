desc 'Loads environment'
task :environment do
  require 'rubygems'
  require 'bundler/setup'
  require 'config/environment'
end

load 'data/load.rake'

task :create_indexes do
  Quarter.create_indexes
  Staffer.create_indexes
  Title.create_indexes
  Office.create_indexes
  # Position.create_indexes
end