task :loading_environment => :environment do
  require 'csv'
  require 'sunlight'
    
  Sunlight::Base.api_key = config[:sunlight_api_key]
end

namespace :load do

  desc "Loads titles from titles.csv"
  task :titles => :loading_environment do
    start = Time.now
    debug = ENV['debug'].present?
    
    # blow away and start from scratch
    Title.delete_all
    
    i = 0
    CSV.foreach("data/csv/titles.csv") do |row|
      i += 1
      next if i == 1 # header row
      
      title_name_original = row[0].strip
      title_name = row[1].blank? ? title_name_original : row[1].strip
      
      if title = Title.where(:name => title_name).first
        title.original_names << title_name_original
        puts "Updated title: #{title_name} with original title #{title_name_original}" if debug
      else
        title = Title.new :name => title_name
        title.original_names = [title_name_original]
        puts "New title: #{title_name} with original title #{title_name_original}" if debug
      end
      
      title.save!
    end
    
    puts "Loaded #{Title.count} titles."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  
  desc "Loads offices from offices.csv"
  task :offices => :loading_environment do
    start = Time.now
    
    offline = ENV['offline'].present?
    
    # don't empty out offices; we don't keep past committees anywhere, so they must be preserved
    committees = offline ? {} : committee_cache
    
    i = 0
    CSV.foreach("data/csv/offices.csv") do |row|
      i += 1
      next if row == 1 # header row
      
      office_from_row row, i, committees
    end
    
    unless offline
      Sunlight::Legislator.all_where(:all_legislators => true).each do |legislator|
        office_from_legislator legislator
      end
    end
    
    puts "Loaded #{Office.count} offices."
    puts "\t#{Office.members.count} members"
    puts "\t#{Office.committees.count} committees"
    puts "\t#{Office.others.count} other offices"
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  
  desc "Loads staffers from staffers.csv"
  task :staffers => :loading_environment do
    start = Time.now
    
    Staffer.delete_all
    
    i = 0
    CSV.foreach("data/csv/staffers.csv") do |row|
      i += 1
      next if i == 1 # header row
      
      staffer_from_row row, i
    end
    
    puts "Loaded #{Staffer.count} staffers."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  

  desc "Loads database (from scratch) from staffers.csv and titles.csv"
  task :positions => :loading_environment do
    start = Time.now
    
    debug = ENV['debug'].present?
    limit = ENV['limit'].present? ? ENV['limit'].to_i : nil
    
    Position.delete_all
    
    i = 0
    CSV.foreach("data/csv/positions.csv") do |row|
      i += 1
      next if i == 1 # header row
      
      # for debugging usage
      return if limit and i > limit
      
      staffer_name_original = strip row[0]
      if staffer_name_original.blank?
        puts "WARNING: No staffer name given, skipping row #{i}"
        next
      end
      
      title_original = strip row[1]
      quarter = strip row[2]
      bioguide_id = strip row[3]
      office_name_original = strip row[4]
      
      # also strip off title addendums, we're ignoring these and collapsing them programmatically
      ["(OTHER COMPENSATION)", "(OVERTIME)"].each do |addendum|
        title_original.sub! addendum, ''
      end
      title_original.strip!
      
      
      unless staffer = Staffer.where(:original_names => staffer_name_original).first
        puts "Couldn't locate staffer by name #{staffer_name_original} in row #{i}, skipping"
        next
      end
      
      unless title = Title.where(:original_names => title_original).first
        puts "Couldn't locate title by name #{title_original} in row #{i}, skipping"
        next
      end
      
      office = nil
      if bioguide_id.present?
        unless office = Office.where("member.bioguide_id" => bioguide_id).first
          puts "Couldn't locate legislator by bioguide_id #{bioguide_id} in row #{i}, skipping"
          next
        end
        
      else
        unless office = Office.where(:original_names => office_name_original).first
          puts "Couldn't locate office by name #{office_name_original} in row #{i}, skipping"
          next
        end
      end
      
      position = Position.where(
        :quarter => quarter,
        "title.name" => title['name'],
        "staffer.slug" => staffer['slug'],
        "office.slug" => office['slug']
      ).first
      
      if position.nil?
        position = Position.new(
          :quarter => quarter,
          :title => title.attributes,
          :staffer => staffer.attributes,
          :office => office.attributes,
          :original_title => title_original
        )
      
        position.save!
      end
      
      puts "[#{i}][#{quarter}] #{staffer.name} works as #{title.name} for #{office.name}" if debug
    end
    
    puts "\nLoaded in #{Position.count} staffer positions."
    puts "\nFinished in #{Time.now - start} seconds."
  end
  
  desc "Load in quarters from positions"
  task :quarters => :loading_environment do
    Quarter.delete_all
    
    Position.all.distinct(:quarter).each do |quarter|
      Quarter.create! :name => quarter
    end
    
    puts "\nLoaded in #{Quarter.count} quarters: #{Quarter.all.map(&:name).join ', '}"
  end
  
  desc "Run all loading tasks in sequence"
  task :all => [:loading_environment, "load:titles", "load:offices", "load:staffers", "load:positions", "load:quarters"] do
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

def strip(str)
  str.present? ? str.strip : nil
end

# office from a row in offices.csv
def office_from_row(row, i, committees)
  office_name_original = strip row[0]
  office_name = strip(row[1]) || office_name_original
  
  committee_id = strip row[2]
  phone = strip row[3]
  building = strip row[4]
  room = strip row[5]
  
  debug = ENV['debug'].present?
  
  if committee_id.present?
    office = Office.where("committee.id" => committee_id).first
    
    # there may be multiple spellings of a given committee that cause it to show up in duplicate rows in committees.csv
    if office
      
      if !office.original_names.include?(office_name_original)
        office.original_names << office_name_original
        puts "Updated committee office: #{office.name} with new original name #{office_name_original}" if debug
      else
        puts "Found old committee office with this name, not touching" if debug
      end

      # in case remote committee data changed
      committee = committees[committee_id]
      if committee
        office.attributes = {
          :name => committee.name,
          :committee => {
            :id => committee_id,
            :name => committee.name,
            :chamber => committee.chamber
          }
        }
        office.save!
      end

    else
      committee = committees[committee_id]
      
      if committee
        office = Office.new :name => committee.name
        office.attributes = {
          :original_names => [office_name_original],
          :office_type => "committee",
          :phone => phone,
          :room => room,
          :building => building,
          :chamber => 'house',
          :committee => {
            :id => committee_id,
            :name => committee.name,
            :chamber => committee.chamber
          }
        }
      else
        puts "BAD OR OLD COMMITTEE_ID: #{committee_id}, row #{i}"
        return
      end
      
      puts "New committee office: #{office.name} with original name #{office_name_original}" if debug
    end
    
    office.save!

  else
    office = Office.where(:name => office_name).first
        
    if office
      
      if !office.original_names.include?(office_name_original)
        office.original_names << office_name_original
        puts "Updated other office: #{office.name} with new original name #{office_name_original}" if debug
      end
      
    else
      office = Office.new :name => office_name
      office.attributes = {
        :original_names => [office_name_original],
        :office_type => "other",
        :phone => phone,
        :room => room,
        :building => building,
        :chamber => 'house'
      }
      
      puts "New other office: #{office.name} with original name #{office_name_original}" if debug
    end
    
    office.save!
  end
end

def office_from_legislator(legislator)
  phone = legislator.phone
  
  room, building = split_office legislator.congress_office
  chamber = legislator.title == 'Sen' ? 'senate' : 'house'

  unless office = Office.where("member.bioguide_id" => legislator.bioguide_id).first
    office = Office.new :name => titled_name(legislator)
    # puts "[#{legislator.bioguide_id}] not found, making new record"
  # else
    # puts "[#{legislator.bioguide_id}] found, updating existing record"
  end
  
  office.attributes = {
    :original_names => [],
    :office_type => "member",
    :phone => phone,
    :room => room,
    :building => building,
    :chamber => chamber,
    :member => {
      :bioguide_id => legislator.bioguide_id,
      :firstname => legislator.firstname,
      :lastname => legislator.lastname,
      :nickname => legislator.nickname,
      :party => legislator.party,
      :name_suffix => legislator.name_suffix,
      :title => legislator.title,
      :chamber => chamber,
      :congress_office => legislator.congress_office,
      :phone => legislator.phone,
      :state => legislator.state,
      :district => legislator.district,
      :in_office => legislator.in_office
    }
  }
  
  # puts "[#{legislator.bioguide_id}] New or updated member office: #{office.name}"
  office.save!
end

def staffer_from_row(row, i)
  debug = ENV['debug'].present?
  
  staffer_name_original = strip row[0]
  staffer_name = strip(row[1]) || staffer_name_original
  
  if staffer_name_original.blank?
    puts "WARNING: no staffer original name provided for row #{i}, skipping"
    return
  end
  
  
  if staffer = Staffer.where(:name => staffer_name).first
    staffer.original_names << staffer_name_original
    puts "[#{i}] Updated staffer: #{staffer_name} with original name #{staffer_name_original}" if debug
    
  else
    # standardize fields
    last_name, first_name = staffer_name.split /,\s?/
    if last_name
      last_name = last_name.split(/\s+/).map {|n| n.capitalize}.join " "
    end
    
    if first_name
      first_name = first_name.split(/\s+/).map {|n| n.capitalize}.join " "
    end
  
    staffer = Staffer.new
    staffer.attributes = {
      :name => [first_name, last_name].join(" "),
      :original_names => [staffer_name_original],
      :first_name => first_name,
      :last_name => last_name,
    }
      
    puts "[#{i}] New staffer: #{staffer_name} with original name #{staffer_name_original}" if debug
  end
  
  staffer.save!
end

def committee_cache
  senate = Sunlight::Committee.all_for_chamber 'Senate'
  house = Sunlight::Committee.all_for_chamber 'House'
  joint = Sunlight::Committee.all_for_chamber 'Joint'
  cache = {}
  (senate + house + joint).each do |comm|
    cache[comm.id] = comm
  end
  
  cache
end