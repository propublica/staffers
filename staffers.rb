#!/usr/bin/env ruby

require 'config/environment'
require 'sinatra/content_for'
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
  # titles = Title.order_by([[:name, :asc]]).all
  quarter_names = Quarter.all.map {|q| q.name}.sort.reverse
  
  # all of them for the dropdown
  committees = Office.committees.order_by([[:name, :asc]]).all
  offices = Office.others.order_by([[:name, :asc]]).all
  
  # first 10 only
  members = Office.legislators.house.order_by([["legislator.in_office", :desc], ["legislator.lastname", :asc], ["legislator.firstname", :asc]]).limit(10).all
  
  erb :index, :locals => {:quarter_names => quarter_names, :committees => committees, :offices => offices, :members => members}
end

get '/faq' do
  erb :faq
end

get '/staffers' do
  search = {}
  
  quarters = []
  if params[:quarter].present?
    quarters = [params[:quarter]]
  else
    quarters = Quarter.all.map {|q| q.name}.sort.reverse
  end
  
  if params[:first_name].present?
    search[:first_name] = /#{params[:first_name]}/i
    
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}"] = {"$exists" => true}
    end
  end
  
  if params[:last_name].present?
    search[:last_name] = /#{params[:last_name]}/i
    
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}"] = {"$exists" => true}
    end
  end
  
  if params[:title].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.title"] = /#{params[:title]}/i
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter}.title" => /#{params[:title]}/i}}
    end
  end

  if params[:state].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.office.legislator.state"] = params[:state]
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter}.office.legislator.state" => params[:state]}}
    end
  end
  
  if params[:party].present?
    if params[:quarter].present?
      search["quarters.#{params[:quarter]}.office.legislator.party"] = params[:party]
    else
      search["$or"] = quarters.map {|quarter| {"quarters.#{quarter}.office.legislator.party" => params[:party]}}
    end
  end
  
  if search.keys.empty?
    staffers = nil
  else
    staffers = Staffer.where(search).order_by([[:last_name, :asc], [:first_name, :asc]]).all
  end
  
  if csv?
    staffers_to_csv staffers, quarters
  else
    erb :staffers, :locals => {:staffers => staffers, :quarters => quarters}
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
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.slug" => params[:slug]).order_by([[:last_name, :asc], [:first_name, :asc]]).all
  end
  
  office_for office, quarters
end

get '/legislator/:bioguide_id' do
  office = Office.where("legislator.bioguide_id" => params[:bioguide_id]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.legislator.bioguide_id" => params[:bioguide_id]).order_by([[:last_name, :asc], [:first_name, :asc]]).all
  end
  
  office_for office, quarters
end

get '/committee/:committee_id' do
  office = Office.where("committee.id" => params[:committee_id]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.committee.id" => params[:committee_id]).order_by([[:last_name, :asc], [:first_name, :asc]]).all
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
  conditions = {}
  
  [:state, :district, :title].each do |key|
    if params[key]
      conditions["legislator.#{key}"] = params[key]
    end
  end
  
  offices_for 'legislators', Office.legislators.house.where(conditions).order_by([["legislator.in_office", :desc], ["legislator.lastname", :asc], ["legislator.firstname", :asc]]).all
end

get %r{^/committees(.csv)?$} do
  offices_for 'committees', Office.committees.order_by([[:name, :asc]]).all
end

get %r{^/offices(.csv)?$} do
  offices_for 'offices', Office.others.order_by([[:name, :asc]]).all
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