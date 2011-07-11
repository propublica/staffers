require 'fastercsv'

def csv?
  (params[:format] == 'csv') or (params[:captures] and (params[:captures][0] == '.csv'))
end

def csv_out(filename)
  response['Content-Type'] = 'text/csv'
  response['Content-Disposition'] = "attachment;filename=#{filename}"
end


# Conversion methods

def legislators_to_csv(legislators)
  csv_out 'legislators.csv'
  
  FasterCSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room",
      "Bioguide ID", "Title", "First Name", "Last Name", "Suffix", 
      "Party", "State", "District", "In Office"
    ]
     
    legislators.each do |legislator|
      leg = legislator['member']
      csv << [
        legislator.name, legislator.phone, legislator.building, legislator.room,
        leg['bioguide_id'], leg['title'], leg['firstname'], leg['lastname'], leg['name_suffix'],
        leg['party'], leg['state'], leg['district'], leg['in_office']
      ]
    end
  end
end

def committees_to_csv(committees)
  csv_out 'committees.csv'
  
  FasterCSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room",
      "Committee ID"
    ]
    
    committees.each do |committee|
      csv << [
        committee.name, committee.phone, committee.building, committee.room,
        committee['committee']['id']
      ]
    end
  end
end

def offices_to_csv(offices)
  csv_out 'offices.csv'
  
  FasterCSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room"
    ]
    
    offices.each do |office|
      csv << [office.name, office.phone, office.building, office.room]
    end
  end
end

def office_to_csv(office, quarters)
  names = {'committee' => 'committee', 'member' => 'member', 'other' => 'office'}
  csv_out "#{names[office.office_type]}.csv"
  
  FasterCSV.generate do |csv|
    csv << [
      "Office", "Quarter", "Staffer", "Title"
    ]
    
    quarters.keys.sort.reverse.each do |quarter|
      staffers = quarters[quarter]
      
      staffers.each do |staffer|
        positions = staffer.positions_for quarter, office
        positions.each do |position|
          csv << [office.name, quarter, staffer.name, position['title']]
        end
      end
    end
  end
end

def staffer_to_csv(staffer)
  csv_out 'staffer.csv'
  
  FasterCSV.generate do |csv|
    csv << [
      "Staffer", "Quarter", "Title", "Office", "Phone", "Building", "Room"
    ]
    
    staffer['quarters'].keys.sort.reverse.each do |quarter|
      positions = staffer['quarters'][quarter]
      positions.each do |position|
        csv << [staffer.name, quarter, position['title'], position['office']['name'], position['office']['phone'], position['office']['building'], position['office']['room']]
      end
    end
  end
end

def staffers_to_csv(staffers, quarters)
  csv_out 'staffers.csv'
  
  FasterCSV.generate do |csv|
    csv << [
      "Staffer", "Quarter", "Title", "Office", "Phone", "Building", "Room"
    ]
    
    staffers.each do |staffer|
      quarters.each do |quarter|
        positions = staffer['quarters'][quarter]
        if positions
          positions.each do |position|
            csv << [staffer.name, quarter, position['title'], position['office']['name'], position['office']['phone'], position['office']['building'], position['office']['room']]
          end
        end
      end
    end
  end
end