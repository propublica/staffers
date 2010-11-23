#!/usr/bin/env ruby

require './config/environment'

require './helpers'

set :views, './views'
set :public, './public'

get '/' do
  erb :index
end

get '/staffers' do
  search = {}
  quarters = Quarter.all
  
  if params[:firstname].present?
    search[:firstname_search] = /#{params[:firstname]}/i
    
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}"] = {"$exists" => true}
    end
  end
  
  if params[:lastname].present?
    search[:lastname_search] = /#{params[:lastname]}/i
    
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}"] = {"$exists" => true}
    end
  end
  
  if params[:title].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.title"] = /#{params[:title]}/i
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter.name}.title" => /#{params[:title]}/i}}
    end
  end

  if params[:state].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.office.legislator.state"] = params[:state]
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter.name}.office.legislator.state" => params[:state]}}
    end
  end
  
  if params[:party].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.office.legislator.party"] = params[:party]
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter.name}.office.legislator.party" => params[:party]}}
    end
  end
  
  if search.keys.empty?
    staffers = nil
  else
    staffers = Staffer.where(search.merge(:order => "lastname_search ASC, firstname_search ASC")).all
  end
  
  erb :search, :locals => {:staffers => staffers, :quarter => params[:quarter]}
end

get '/staffer/:id' do
  staffer = Staffer.where(:_id => BSON::ObjectId(params[:id])).first
  
  erb :staffer, :locals => {:staffer => staffer}
end

get '/office/:id' do
  office = Office.where(:_id => BSON::ObjectId(params[:id])).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office._id" => office._id).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  erb :office, :locals => {:office => office, :quarters => quarters}
end

get '/offices' do
  offices = nil
  
  if params[:type] == 'member'
    offices = Office.where(:office_type => 'member').order_by([["legislator.lastname", :asc], ["legislator.firstname", :asc]]).all
  elsif params[:type] == 'committee'
    offices = Office.where(:office_type => 'committee').order_by([[:name, :asc]]).all
  elsif params[:type] == 'other'
    offices = Office.where(:office_type => 'other').order_by([[:name, :asc]]).all
  end
  
  erb :offices, :locals => {:offices => offices, :type => params[:type]}
end
