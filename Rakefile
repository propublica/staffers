desc 'Loads environment'
task :environment do
  require 'staffers'
end

namespace :staffers do
  desc "Loads database (from scratch) from staffers.csv and titles.csv"
  task :load => :environment do
    start = Time.now
    
    require 'fastercsv'
    require 'sunlight'
    
    Sunlight::Base.api_key = config[:sunlight_api_key]
    
    
    # cache legislators from Congress API
    legislator_cache = {}
    (Sunlight::Legislator.all_where(:in_office => 1) + Sunlight::Legislator.all_where(:in_office => 0)).each do |legislator|
      legislator_cache[legislator.bioguide_id] = legislator
    end
    
    
    # clear out database
    Office.delete_all
    Staffer.delete_all
    Quarter.delete_all
    Title.delete_all
    
    
    # create a hash of titles from titles.csv
    titles = {}
    i = 0
    FasterCSV.foreach("data/titles.csv") do |row|
      i += 1
      
      next if row[0] == "PURPOSE Field" # header row
      
      if row[0].blank? or row[1].blank?
        puts "ERROR: missing title info in row #{i}, skipping title"
        next
      else
        titles[row[0].strip] = row[1].strip
      end
    end
    
    titles.values.uniq.each do |title|
      Title.create! :name => title
    end
    
    quarters = []
    
    i = 0
    FasterCSV.foreach("data/staffers.csv") do |row|
      i += 1
      next if row[0] == "BIOGUIDE_ID" # header row
      
      # office information
      bioguide_id = row[0]
      committee_id = row[2]
      office_name = row[3].present? ? row[3] : row[4]
      phone = row[5]
      building = row[6]
      room = row[7]
      
      office_name = office_name.strip if office_name
      
      office = nil
      
      if bioguide_id.present?
        office = Office.first "legislator.bioguide_id" => bioguide_id
        
        if office.nil?
          # fetch legislator from Sunlight API, falling back to out of office if first call fails
          legislator = legislator_cache[bioguide_id]
          
          # override phone, room, and building
          phone = legislator.phone
          room, building = split_office legislator.congress_office
          
          if legislator
            office = Office.new :name => titled_name(legislator)
            office.attributes = {
              :type => "member",
              :phone => phone,
              :room => room,
              :building => building,
              :legislator => {
                :bioguide_id => bioguide_id,
                :firstname => legislator.firstname,
                :lastname => legislator.lastname,
                :firstname_search => legislator.firstname.downcase,
                :lastname_search => legislator.lastname.downcase,
                :nickname => legislator.nickname,
                :party => legislator.party,
                :name_suffix => legislator.name_suffix,
                :title => legislator.title,
                :congress_office => legislator.congress_office,
                :phone => legislator.phone,
                :state => legislator.state,
                :district => legislator.district,
                :in_office => legislator.in_office
              }
            }
          else
            puts "BAD BIOGUIDE_ID: #{bioguide_id}, row #{i}"
            next
          end
          
          # puts "New member office: #{office.name}"
          office.save!
        end

      elsif committee_id.present?
        office = Office.first "committee.id" => committee_id
        
        if office.nil?
          committee = Sunlight::Committee.get committee_id
          
          if committee
            office = Office.new :name => committee.name
            office.attributes = {
              :type => "committee",
              :phone => phone,
              :room => room,
              :building => building,
              :committee => {
                :id => committee_id,
                :name => committee.name,
                :chamber => committee.chamber
              }
            }
          else
            puts "BAD COMMITTEE_ID: #{committee_id}, row #{i}"
            next
          end
          
          # puts "New committee office: #{office.name}"
          office.save!
        end
        
      else
        if office_name.blank?
          puts "ERROR: Missing office name, row #{i}"
          next
        end
        
        office = Office.first :name => office_name
        
        if office.nil?
          office = Office.new :name => office_name
          office.attributes = {
            :type => "other",
            :phone => phone,
            :room => room,
            :building => building
          }
          
          # puts "New office: #{office.name}"
          office.save!
        end
      end
      
      
      # Staffer information
      name_original = row[13]
      title_original = row[11]
      
      if name_original.blank? or title_original.blank?
        puts "ERROR: Missing original name or title, row #{i}"
        next
      end
      
      title_original = title_original.strip
      
      # standardize fields
      lastname, firstname = name_original.split /,\s?/
      lastname_search = nil
      firstname_search = nil
      if lastname
        lastname = lastname.split(/\s+/).map {|n| n.capitalize}.join " "
        lastname_search = lastname.downcase
      end
      if firstname
        firstname = firstname.split(/\s+/).map {|n| n.capitalize}.join " "
        firstname_search = firstname.downcase
      end
      
      title = titles[title_original] || title_original
      
      # quarter scoping this office role
      quarter = row[8]
      quarters << quarter
      
      
      staffer = Staffer.first :name_original => name_original
      if staffer.nil?
        staffer = Staffer.new :name_original => name_original
        staffer.attributes = {
          :firstname => firstname,
          :lastname => lastname,
          :firstname_search => firstname_search,
          :lastname_search => lastname_search,
          :quarters => {}
        }
      end
      
      staffer[:quarters][quarter] ||= []
      
      match = staffer[:quarters][quarter].detect do |position|
        (position['title'] == title) and (position['office']['name'] == office.name)
      end
      
      unless match
        staffer[:quarters][quarter] << {
          :title => title,
          :title_original => title_original,
          :office => office.attributes
        }
      end
      
      staffer.save!
    end
    
    quarters = quarters.uniq
    quarters.each do |quarter|
      Quarter.create! :name => quarter
    end
    
    # create indexes based on these quarters
    quarters.each do |quarter|
      Staffer.ensure_index "quarters.#{quarter}.office.legislator.firstname_search"
      Staffer.ensure_index "quarters.#{quarter}.office.legislator.lastname_search"
      Staffer.ensure_index "quarters.#{quarter}.office.legislator.state"
      Staffer.ensure_index "quarters.#{quarter}.office._id"
      Staffer.ensure_index "quarters.#{quarter}.title"
    end
    
    puts "\nLoaded in #{Staffer.count} staffers in #{Office.count} offices."
    puts "\t#{Office.count :type => "member"} members"
    puts "\t#{Office.count :type => "committee"} committees"
    puts "\t#{Office.count :type => "other"} other offices"
    
    puts "\nFinished in #{Time.now - start} seconds."
  end
end

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

# format name from Sunlight API
def titled_name(legislator)
  "#{legislator.title}. #{legislator.nickname.present? ? legislator.nickname : legislator.firstname} #{legislator.lastname} #{legislator.name_suffix}".strip
end

# split congress_office out into room and building
def split_office(congress_office)
  words = congress_office.split ' '
  [words[0], words[1]]
end