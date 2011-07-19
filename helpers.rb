helpers do
  
  def out?(office)
    office.office_type == 'member' and office['legislator']['in_office'] == false
  end
  
  def office_path(office)
    if office['office_type'] == "member"
      "/legislator/#{office['member']['bioguide_id']}"
    elsif office['office_type'] == "committee"
      "/committee/#{office['committee']['id']}"
    else
      "/office/#{office['slug']}"
    end
  end
  
  def staffer_path(staffer)
    "/staffer/#{staffer['slug']}"
  end
  
  def csv_path
    "#{request.fullpath}#{request.fullpath['?'] ? "&" : "?"}format=csv"
  end
  
  def capitalize(words)
    first_pass = words.split(' ').map {|word| word.capitalize}.join ' '
    first_pass.gsub(/\/(\w)/) {" / #{$1.upcase}"}
  end
  
  def title_listing(title)
    name = capitalize title['name']
    original_names = title['original_names'].join("<br/>").gsub("\"", "\\\"")
    "#{name} <a href=\"#\" onclick=\"return false\" class=\"info-icon\" title=\"Titles as originally listed:<br/><br/>#{original_names}\">i</a>"
  end
  
  def display_name(staffer)
    "#{staffer['first_name']} #{staffer['last_name']}".strip
  end
  
  def list_name(staffer)
    "#{staffer.lastname}, #{staffer.firstname}".strip
  end
  
  def format_quarter(quarter)
    pieces = quarter.match /^(\d+)Q(\d)/
    year = pieces[1]
    quarter = pieces[2]
    ordinal = {
      "1" => "st",
      "2" => "nd",
      "3" => "rd",
      "4" => "th"
    }[quarter]
    
    "#{year} #{quarter}#{ordinal} Quarter"
  end
  
  def room_for(building, room)
    if building and room
      "#{room} #{building.split(' ').first}"
    else
      nil
    end
  end
  
  def district_for(district)
    if district.to_i == 0
      "At-Large"
    else
      district
    end
  end
  
  def plural_title_for(title)
    {
      "Del" => "Delegates",
      "Sen" => "Senators",
      "Com" => "Commissioners",
      "Rep" => "Representatives"
    }[title]
  end
  
  def state_codes
    {
      "AL" => "Alabama",
      "AK" => "Alaska",
      "AZ" => "Arizona",
      "AR" => "Arkansas",
      "CA" => "California",
      "CO" => "Colorado",
      "CT" => "Connecticut",
      "DE" => "Delaware",
      "DC" => "District of Columbia",
      "FL" => "Florida",
      "GA" => "Georgia",
      "HI" => "Hawaii",
      "ID" => "Idaho",
      "IL" => "Illinois",
      "IN" => "Indiana",
      "IA" => "Iowa",
      "KS" => "Kansas",
      "KY" => "Kentucky",
      "LA" => "Louisiana",
      "ME" => "Maine",
      "MD" => "Maryland",
      "MA" => "Massachusetts",
      "MI" => "Michigan",
      "MN" => "Minnesota",
      "MS" => "Mississippi",
      "MO" => "Missouri",
      "MT" => "Montana",
      "NE" => "Nebraska",
      "NV" => "Nevada",
      "NH" => "New Hampshire",
      "NJ" => "New Jersey",
      "NM" => "New Mexico",
      "NY" => "New York",
      "NC" => "North Carolina",
      "ND" => "North Dakota",
      "OH" => "Ohio",
      "OK" => "Oklahoma",
      "OR" => "Oregon",
      "PA" => "Pennsylvania",
      "PR" => "Puerto Rico",
      "RI" => "Rhode Island",
      "SC" => "South Carolina",
      "SD" => "South Dakota",
      "TN" => "Tennessee",
      "TX" => "Texas",
      "UT" => "Utah",
      "VT" => "Vermont",
      "VA" => "Virginia",
      "WA" => "Washington",
      "WV" => "West Virginia",
      "WI" => "Wisconsin",
      "WY" => "Wyoming"
    }
  end
  
  def party_names
    {
      "R" => "Republican",
      "D" => "Democrat",
      "I" => "Independent"
    }
  end
  
  def search_titles
    [
      "Case Worker",
      "Chief of Staff",
      "Clerk",
      "Constituent Liaison",
      "Counsel",
      "District Director",
      "Executive Assistant",
      "Legislative Assistant",
      "Legislative Correspondent",
      "Legislative Director",
      "Office Manager",
      "Press Secretary",
      "Professional Staff",
      "Research Assistant",
      "Scheduler",
      "Staff Assistant",
      "System Administrator"
    ]
  end
  
end