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
  members = Office.members.house.order_by([["member.in_office", :desc], ["member.lastname", :asc], ["member.firstname", :asc]]).limit(10).all
  
  erb :index, :locals => {:quarter_names => quarter_names, :committees => committees, :offices => offices, :members => members}
end

get '/faq' do
  erb :faq
end

get '/staffers' do
  search = {}
  
  if params[:quarter].present?
    search[:quarter] = params[:quarter]
  end
  
  if params[:first_name].present?
    search["staffer.first_name"] = regex_for params[:first_name]
  end
  
  if params[:last_name].present?
    search["staffer.last_name"] = regex_for params[:last_name]
  end
  
  if params[:title].present?
    search["title.name"] = regex_for params[:title]
  end

  if params[:state].present?
    search["office.member.state"] = params[:state]
  end
  
  if params[:party].present?
    search["office.member.party"] = params[:party]
  end
  
  if search.keys.empty?
    positions = nil
  else
    positions = Position.where(search).desc(:quarter).all
    positions = positions.limit(50)
  end
  
  if csv?
    positions_to_csv positions
  else
    erb :positions, :locals => {:positions => positions}
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
  office = Office.where("member.bioguide_id" => params[:bioguide_id]).first
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.where("quarters.#{quarter.name}.office.member.bioguide_id" => params[:bioguide_id]).order_by([[:last_name, :asc], [:first_name, :asc]]).all
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
      conditions["member.#{key}"] = params[key]
    end
  end
  
  offices_for 'legislators', Office.members.house.where(conditions).order_by([["member.in_office", :desc], ["member.lastname", :asc], ["member.firstname", :asc]]).all
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

def regex_for(value)
  regex_value = value.dup
  %w{+ ? . * ^ $ ( ) [ ] { } | \ }.each {|char| regex_value.gsub! char, "\\#{char}"}
  /#{regex_value}/i
end