require 'fastercsv'

def csv_out
  response['Content-Type'] = 'text/csv'
end

def csv?
  params[:captures] and (params[:captures][0] == '.csv')
end


# Conversion methods

def legislators_to_csv(legislators)
  csv_out
  
  FasterCSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room",
      "Bioguide ID", "Title", "First Name", "Last Name", "Suffix", 
      "Party", "State", "District", "In Office"
    ]
     
    legislators.each do |legislator|
      leg = legislator['legislator']
      csv << [
        legislator.name, legislator.phone, legislator.building, legislator.room,
        leg['bioguide_id'], leg['title'], leg['firstname'], leg['lastname'], leg['name_suffix'],
        leg['party'], leg['state'], leg['district'], leg['in_office']
      ]
    end
  end
end

def offices_to_csv(offices)
end

def staffers_to_csv(staffers)
  
end

def staffer_to_csv(staffer)
end

def office_to_csv(office)
end