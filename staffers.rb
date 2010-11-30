#!/usr/bin/env ruby

require 'config/environment'
require './csv'
require 'helpers'

# reload in development without starting server
configure(:development) do |config|
  require 'sinatra/reloader'
  config.also_reload "config/environment.rb"
  config.also_reload "models.rb"
  config.also_reload "helpers.rb"
  config.also_reload "./csv.rb"
end

set :public, 'public'
set :views, 'views'

get '/' do
  erb :index
end

get '/faq' do
  erb :faq
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
  
  if csv?
    staffers_to_csv staffers, params[:quarter]
  else
    erb :staffers, :locals => {:staffers => staffers, :quarter => params[:quarter]}
  end
end

get '/staffer/:slug' do
  staffer = Staffer.where(:slug => params[:slug]).first
  
  if csv?
    staffer_to_csv staffer
  else
    erb :staffer, :locals => {:staffer => staffer}
  end
end


# office URLs
get '/office/:slug' do
  office = Office.where(:slug => params[:slug]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.slug" => params[:slug]).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  office_for office, quarters
end

get '/legislator/:bioguide_id' do
  office = Office.where("legislator.bioguide_id" => params[:bioguide_id]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.legislator.bioguide_id" => params[:bioguide_id]).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  office_for office, quarters
end

get '/committee/:committee_id' do
  office = Office.where("committee.id" => params[:committee_id]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.committee.id" => params[:committee_id]).order_by([[:lastname_search, :asc], [:firstname_search, :asc]]).all
  end
  
  office_for office, quarters
end

def office_for(office, quarters)
  if csv?
    office_to_csv office, quarters
  else
    erb :office, :locals => {:office => office, :quarters => quarters}
  end
end



get %r{^/legislators(.csv)?$} do
  conditions = {:office_type => 'member', :chamber => 'house'}
  
  [:state, :district, :title].each do |key|
    if params[key]
      conditions["legislator.#{key}"] = params[key]
    end
  end
  
  offices_for 'legislators', Office.where(conditions).order_by([["legislator.in_office", :desc], ["legislator.lastname", :asc], ["legislator.firstname", :asc]]).all
end

get %r{^/committees(.csv)?$} do
  offices_for 'committees', Office.where(:office_type => 'committee').order_by([[:name, :asc]]).all
end

get %r{^/offices(.csv)?$} do
  offices_for 'offices', Office.where(:office_type => 'other').order_by([[:name, :asc]]).all
end


def offices_for(type, offices)
  if csv?
    if type == 'legislators'
      legislators_to_csv offices
    elsif type == 'committees'
      committees_to_csv offices
    else
      offices_to_csv offices
    end
  else
    erb :offices, :locals => {:offices => offices, :type => type}
  end
end