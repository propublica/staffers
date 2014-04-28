require 'csv'

def csv?
  (params[:format] == 'csv') or (params[:captures] and (params[:captures][0] == '.csv'))
end

def csv_out(filename)
  response['Content-Type'] = 'text/csv'
  response['Content-Disposition'] = "attachment;filename=#{filename}"
end



def members_to_csv(members)
  csv_out 'members.csv'

  CSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room",
      "Bioguide ID", "Title", "First Name", "Last Name", "Suffix",
      "Party", "State", "District", "In Office"
    ]

    members.each do |member|
      leg = member['member']
      csv << [
        member.name, member.phone, member.building, member.room,
        leg['bioguide_id'], leg['title'], leg['firstname'], leg['lastname'], leg['name_suffix'],
        leg['party'], leg['state'], leg['district'], leg['in_office']
      ]
    end
  end
end

def committees_to_csv(committees)
  csv_out 'committees.csv'

  CSV.generate do |csv|
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

  CSV.generate do |csv|
    csv << [
      "Name", "Phone", "Building", "Room"
    ]

    offices.each do |office|
      csv << [office.name, office.phone, office.building, office.room]
    end
  end
end

def office_to_csv(office, positions)
  names = {'committee' => 'committee', 'member' => 'member', 'other' => 'office'}
  csv_out "#{names[office.office_type]}.csv"

  CSV.generate do |csv|
    csv << [
      "Office", "Quarter", "Staffer", "Title"
    ]

    positions.each do |position|
      csv << [position['office']['name'], position['quarter'], position['staffer']['name'], position['title']['name']]
    end
  end
end

def staffer_to_csv(staffer, positions)
  csv_out 'staffer.csv'

  CSV.generate do |csv|
    csv << [
      "Staffer", "Quarter", "Title", "Office", "Phone", "Building", "Room"
    ]

    positions.each do |position|
      csv << [staffer.name, position['quarter'], position['title']['name'], position['office']['name'], position['office']['phone'], position['office']['building'], position['office']['room']]
    end
  end
end

def positions_to_csv(positions)
  csv_out 'positions.csv'

  CSV.generate do |csv|
    csv << [
      "Staffer", "Quarter", "Title", "Office", "Phone", "Building", "Room"
    ]

    positions.each do |position|
      csv << [position['staffer']['name'], position['quarter'], position['title']['name'], position['office']['name'], position['office']['phone'], position['office']['building'], position['office']['room']]
    end
  end
end