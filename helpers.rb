helpers do
  
  def display_name(staffer)
    "#{staffer.firstname} #{staffer.lastname}".strip
  end
  
  def display_offices_for(staffer, quarter)
    positions = staffer.quarters[quarter]
    if positions
      "<strong>#{quarter}</strong>: " + positions.map do |position| 
        position['office']['name']
      end.join(", ")
    else
      ""
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
end