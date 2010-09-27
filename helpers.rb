helpers do
  
  def capitalize(words)
    first_pass = words.split(' ').map {|word| word.capitalize}.join ' '
    first_pass.gsub(/\/(\w)/) {" / #{$1.upcase}"}
  end
  
  def display_name(staffer)
    "#{staffer.firstname} #{staffer.lastname}".strip
  end
  
  def list_name(staffer)
    "#{staffer.lastname}, #{staffer.firstname}".strip
  end
  
  def format_quarter(quarter)
    pieces = quarter.match /^(\d+)(Q\d)/
    "#{pieces[1]} #{pieces[2]}"
  end
  
  def room_for(building, room)
    if building and room
      "#{room} #{building.split(' ').first}"
    else
      nil
    end
  end
  
  def state_select
    states_by_name = state_codes.invert
    "<select name=\"state\">\n" +
      "\t<option value=\"\">----</option>" +
      states_by_name.keys.sort.map do |name|
        "\t<option value=\"#{states_by_name[name]}\">#{name}</option>"
      end.join("\n") +
      "\n</select>"
  end
  
  def party_select
    parties_by_name = party_names.invert
    "<select name=\"party\">\n" +
      "\t<option value=\"\">----</option>" +
      parties_by_name.keys.sort.map do |name|
        "\t<option value=\"#{parties_by_name[name]}\">#{name}</option>"
      end.join("\n") +
      "\n>/select>"
  end  
  
  def quarter_select
    "<select name=\"quarter\">\n" +
      Quarter.all.map {|q| q.name}.sort.reverse.map do |quarter|
        "\t<option>#{quarter}</option>"
      end.join("\n") +
      "\n</select>"
  end
  
  def title_select
    "<select name=\"title\">\n" +
      Title.all.map {|t| t.name}.compact.sort.map do |title|
        "\t<option>#{title}</option>"
      end.join("\n") +
      "\n</select>"
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
  
end