namespace :staffers do
  desc "Loads database (from scratch) from staffers.csv and titles.csv"
  task :load => :environment do
    start = Time.now
    
    require 'csv'
    require 'sunlight'
    
    Sunlight::Base.api_key = config[:sunlight_api_key]
    
    
    # clear out database
    Office.delete_all
    Staffer.delete_all
    Quarter.delete_all
    Title.delete_all
    
    
    # load titles into a hash
    titles = {}
    i = 0
    CSV.foreach("data/csv/titles.csv") do |row|
      i += 1
      next if row[0] == "TITLE (ORIGINAL)" # header row
      
      title_from_row row
    end
    
    
    # Create offices, first committees and others from CSV
    CSV.foreach("data/csv/offices.csv") do |row|
      i += 1
      next if row[0] == "OFFICE NAME (ORIGINAL)" # header row
      
      office_from_row row
    end
    
    return #TODO
   
    # then from all known legislators
    legislator_cache = {}
    (Sunlight::Legislator.all_where(:in_office => 1) + Sunlight::Legislator.all_where(:in_office => 0)).each do |legislator|
      legislator_cache[legislator.bioguide_id] = legislator
    end
    
    #TODO: iterate over each
    
    
    
    quarters = []
    
    i = 0
    CSV.foreach("data/csv/staffers.csv") do |row|
      i += 1
      next if row[0] == "BIOGUIDE_ID" # header row
      
      # office information
      bioguide_id = row[0]
      committee_id = row[2]
      office_name = row[3]
      office_name_original = row[4]
      phone = row[5]
      building = row[6]
      room = row[7]
      
      office_name = office_name.strip if office_name
      office_name_original = office_name_original.strip if office_name_original
      
      if office_name.blank?
        office_name = office_name_original
      end
      
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
              :name_original => office_name_original,
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
    puts "\nLoaded in #{Title.count} titles."
    
    puts "\nFinished in #{Time.now - start} seconds."
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
      
      puts "New committee office: #{office.name} with original name #{office_name_original}"
    end
    
    office.save!
  else
    office = Office.first :name => office_name
        
    if office
      office.original_names << office_name_original
      puts "Updated other office: #{office.name} with new original name #{office_name_original}"
    else
      office = Office.new :name => office_name
      office.attributes = {
        :original_names => [office_name_original],
        :type => "other",
        :phone => phone,
        :room => room,
        :building => building
      }
      
      puts "New other office: #{office.name} with original name #{office_name_original}"
    end
    
    office.save!
  end
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
    puts "Updated title: #{title_name} with original title #{title_name_original}"
  else
    title = Title.new :name => title_name
    title.original_names = [title_name_original]
    puts "New title: #{title_name} with original title #{title_name_original}"
  end
  
  title.save!
end