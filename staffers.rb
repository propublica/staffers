#!/usr/bin/env ruby

require 'config/environment'
require 'helpers'

# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "config/environment.rb"
  config.also_reload "helpers.rb"
  config.also_reload "models.rb"
end

set :public, 'public'
set :views, 'views'

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
    staffers = Staffer.where(search).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  erb :search, :locals => {:staffers => staffers, :quarter => params[:quarter]}
end

get '/staffer/:slug' do
  staffer = Staffer.where(:slug => params[:slug]).first
  
  erb :staffer, :locals => {:staffer => staffer}
end

# office URLs
get '/office/:slug' do
  office_for Office.where(:slug => params[:slug]).first
end

get '/legislator/:bioguide_id' do
  office_for Office.where("legislator.bioguide_id" => params[:bioguide_id]).first
end

get '/committee/:committee_id' do
  office_for Office.where("committee.id" => params[:committee_id]).first
end

def office_for(office)
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office._id" => office._id).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  erb :office, :locals => {:office => office, :quarters => quarters}
end


get '/legislators' do
  offices_for Office.where(:office_type => 'member').order_by([["legislator.lastname", :asc], ["legislator.firstname", :asc]]).all
end

get '/committees' do
  offices_for Office.where(:office_type => 'committee').order_by([[:name, :asc]]).all
end

get '/offices' do
  offices_for Office.where(:office_type => 'other').order_by([[:name, :asc]]).all
end

def offices_for(offices)
  erb :offices, :locals => {:offices => offices, :type => params[:type]}
end
