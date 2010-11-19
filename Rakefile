desc 'Loads environment'
task :environment do
  require './staffers'
end

load 'data/load.rake'

namespace :fixtures do

  desc "Load all fixtures, or one model's"
  task :load => :environment do
    fixtures = ENV['model'] ? [ENV['model']] : all_fixtures
    fixtures.each {|name| restore_fixture name}
  end
  
  desc "Dump all models into fixtures, or one model"
  task :dump => :environment do
    fixtures = ENV['model'] ? [ENV['model']] : all_fixtures
    fixtures.each {|name| dump_fixture name}
  end
  
  def all_fixtures
    Dir.glob("fixtures/*.yml").map {|f| File.basename(f, ".yml")}
  end

end

def restore_fixture(name)
  model = name.singularize.camelize.constantize
  model.delete_all
  
  YAML::load_file("fixtures/#{collection}.yml").each do |row|
    record = model.new
    row.keys.each do |field|
      record[field] = row[field] if row[field]
    end
    record.save
  end
  
  puts "Loaded #{name} collection from fixtures"
end

def dump_fixture(name)
  collection = MongoMapper.database.collection name
  records = []
  
  collection.find({}, {:limit => 5}).each do |record|
    records << record_to_hash(record)
  end
  
  FileUtils.mkdir_p "fixtures"
  File.open("fixtures/#{name}.yml", "w") do |file|
    YAML.dump records, file
  end
  
  puts "Dumped #{name} collection to fixtures"
end

def record_to_hash(record)
  return record unless record.class == BSON::OrderedHash
  
  new_record = {}
  
  record.delete '_id'
  record.each do |key, value|
  
    if value.class == Array
      new_record[key] = value.map {|object| record_to_hash object}
    else
      new_record[key] = record_to_hash value
    end
    
  end
  
  new_record
end