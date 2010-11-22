task :loading_environment => :environment do
  require 'csv'
  require 'sunlight'
    
  Sunlight::Base.api_key = config[:sunlight_api_key]
end

namespace :load do

  desc "Loads titles from titles.csv"
  task :titles => :loading_environment do
    start = Time.now
    
    Title.delete_all
    
    CSV.foreach("data/csv/titles.csv") do |row|
      next if row[0] == "TITLE (ORIGINAL)" # header row
      
      title_from_row row
    end
    
    puts "Loaded #{Title.count} titles."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  
  desc "Loads offices from offices.csv"
  task :offices => :loading_environment do
    start = Time.now
    
    Office.delete_all
    
    CSV.foreach("data/csv/offices.csv") do |row|
      next if row[0] == "OFFICE NAME (ORIGINAL)" # header row
      
      office_from_row row
    end
    
    Sunlight::Legislator.all_where(:all_legislators => true).each do |legislator|
      office_from_legislator legislator
    end
    
    puts "Loaded #{Office.count} offices."
    puts "\t#{Office.count :type => "member"} members"
    puts "\t#{Office.count :type => "committee"} committees"
    puts "\t#{Office.count :type => "other"} other offices"
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  
  desc "Loads staffers from staffers.csv"
  task :staffers => :loading_environment do
    start = Time.now
    
    Staffer.delete_all
    
    i = 0
    CSV.foreach("data/csv/staffers.csv") do |row|
      i += 1
      next if row[0] == "STAFFER NAME (ORIGINAL)" # header row
      
      staffer_from_row row, i
    end
    
    puts "Loaded #{Staffer.count} staffers."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  

  desc "Loads database (from scratch) from staffers.csv and titles.csv"
  task :positions => :loading_environment do
    start = Time.now
    
    # clear out database
    Quarter.delete_all
    
    
    quarters = []
    
    i = 0
    CSV.foreach("data/csv/positions.csv") do |row|
      i += 1
      next if row[0] == "STAFFER NAME (ORIGINAL)" # header row
      
      staffer_name_original = row[0]
      if staffer_name_original.blank?
        puts "WARNING: No staffer name given, skipping row #{i}"
        next
      else
        staffer_name_original = staffer_name_original.strip
      end
      
      title_original = row[1].strip
      quarter = row[2]
      bioguide_id = row[3]
      office_name_original = row[4].strip
      
      quarters << quarter unless quarters.include? quarter
      
      
      staffer = Staffer.first :original_names => staffer_name_original
      if staffer.nil?
        puts "Couldn't locate staffer by name #{staffer_name_original} in row #{i}, skipping"
        next
      end
      
      title = Title.first :original_names => title_original
      if title.nil?
        puts "Couldn't locate title by name #{title_original} in row #{i}, skipping"
        next
      end
      
      if bioguide_id.present?
        office = Office.first "legislator.bioguide_id" => bioguide_id
        if office.nil?
          puts "Couldn't locate legislator by bioguide_id #{bioguide_id} in row #{i}, skipping"
          next
        else
          # while I'm here, store any known original office name
          office.original_names << office_name_original unless office_name_original.blank?
        end
      else
        office = Office.first :original_names => office_name_original
        if office.nil?
          puts "Couldn't locate office by name #{office_name_original} in row #{i}, skipping"
          next
        end
      end
      
      staffer[:quarters][quarter] ||= []
      staffer[:quarters][quarter] << {
        :title => title.name,
        :title_original => title_original,
        :office => office.attributes
      }
      
      # puts "Added #{quarter} position #{title.name} to #{staffer.name}"
      
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
      Staffer.ensure_index "quarters.#{quarter}.office.legislator.party"
      Staffer.ensure_index "quarters.#{quarter}.office._id"
      Staffer.ensure_index "quarters.#{quarter}.title"
    end
    
    puts "\nLoaded in #{i} staffer positions."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  
  desc "Run all loading tasks in sequence"
  task :all => [:loading_environment, "load:titles", "load:offices", "load:staffers", "load:positions"] do
  end
  
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

# office from a row in offices.csv
def office_from_row(row)
  office_name_original = row[0]
  office_name = row[1]
  committee_id = row[2]
  phone = row[3]
  building = row[4]
  room = row[5]
  
  office_name = office_name.strip if office_name
  office_name_original = office_name_original.strip if office_name_original
  
  if office_name.blank?
    office_name = office_name_original
  end
  
  if committee_id.present?
    office = Office.first "committee.id" => committee_id
    
    # there may be multiple spellings of a given committee that cause it to show up in duplicate rows in committees.csv
    if office
      office.original_names << office_name_original
      puts "Updated committee office: #{office.name} with new original name #{office_name_original}"
    else
      committee = Sunlight::Committee.get committee_id
      
      if committee
        office = Office.new :name => committee.name
        office.attributes = {
          :original_names => [office_name_original],
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
      
      # puts "New committee office: #{office.name} with original name #{office_name_original}"
    end
    
    office.save!
  else
    office = Office.first :name => office_name
        
    if office
      office.original_names << office_name_original
      # puts "Updated other office: #{office.name} with new original name #{office_name_original}"
    else
      office = Office.new :name => office_name
      office.attributes = {
        :original_names => [office_name_original],
        :type => "other",
        :phone => phone,
        :room => room,
        :building => building
      }
      
      # puts "New other office: #{office.name} with original name #{office_name_original}"
    end
    
    office.save!
  end
end

def office_from_legislator(legislator)
  phone = legislator.phone
  room, building = split_office legislator.congress_office

  office = Office.new :name => titled_name(legislator)
  office.attributes = {
    :original_names => [],
    :type => "member",
    :phone => phone,
    :room => room,
    :building => building,
    :legislator => {
      :bioguide_id => legislator.bioguide_id,
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
  
  # puts "New member office: #{office.name}"
  office.save!
end

def title_from_row(row)
  title_name_original = row[0].strip
  title_name = row[1]
  if title_name.blank?
    title_name = title_name_original
  else
    title_name = title_name.strip
  end
  
  title = Title.first :name => title_name
  
  if title
    title.original_names << title_name_original
    # puts "Updated title: #{title_name} with original title #{title_name_original}"
  else
    title = Title.new :name => title_name
    title.original_names = [title_name_original]
    # puts "New title: #{title_name} with original title #{title_name_original}"
  end
  
  title.save!
end

def staffer_from_row(row, i)
  staffer_name_original = row[0]
  staffer_name = row[1]
  
  if staffer_name_original.blank?
    puts "WARNING: no staffer original name provided for row #{i} (not inc. header row), skipping"
    return
  else
    staffer_name_original = staffer_name_original.strip
  end
  
  
  if staffer_name.blank?
    staffer_name = staffer_name_original
  else
    staffer_name = staffer_name.strip
  end
  
  staffer = Staffer.first :name => staffer_name
  
  if staffer
    staffer.original_names << staffer_name_original
    # puts "[#{i}] Updated staffer: #{staffer_name} with original name #{staffer_name_original}"
  else
    staffer = Staffer.new :name => staffer_name
    
    # standardize fields
    lastname, firstname = staffer_name_original.split /,\s?/
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
  
    staffer.attributes = {
      :original_names => [staffer_name_original],
      :firstname => firstname,
      :lastname => lastname,
      :firstname_search => firstname_search,
      :lastname_search => lastname_search,
      :quarters => {}
    }
      
    # puts "[#{i}] New staffer: #{staffer_name} with original name #{staffer_name_original}"
  end
  
  staffer.save!
end