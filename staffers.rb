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

# used by the search dropdown
before do
  @committees = Office.committees.order_by([[:name, :asc]]).all
  @offices = Office.others.order_by([[:name, :asc]]).all
  @quarter_names = Quarter.all.distinct(:name).sort.reverse
end

get '/' do
  # first 10 only
  members = Office.members.house.order_by([["member.in_office", :desc], ["member.lastname", :asc], ["member.firstname", :asc]]).limit(10).all
  
  erb :index, :locals => {:committees => @committees, :offices => @offices, :members => members}
end

get '/faq' do
  erb :faq
end

get '/positions' do
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
  
  if params[:office].present?
    search["office.slug"] = params[:office]
  end
  
  if params[:committee].present?
    search["office.slug"] = params[:committee]
  end
  
  if search.keys.empty?
    positions = nil
  else
    positions = Position.where(search).desc(:quarter).all
    # positions = positions.limit(50)
  end
  
  if csv?
    positions_to_csv positions
  else
    erb :positions, :locals => {:positions => positions}
  end
end

get '/staffer/:slug' do
  staffer = Staffer.where(:slug => params[:slug]).first
  positions = Position.where("staffer.slug" => params[:slug]).all
  
  if csv?
    staffer_to_csv staffer, positions
  else
    erb :staffer, :locals => {:staffer => staffer, :positions => positions}
  end
end


# office URLs
get '/office/:slug' do
  office = Office.where(:slug => params[:slug]).first
  positions = Position.where("office.slug" => params[:slug]).all
  
  if csv?
    office_to_csv office, positions
  else
    erb :office, :locals => {:office => office, :positions => positions}
  end
end

# support legacy /legislator/ URL
get %r{/(?:member|legislator)/(\w\d+)} do
  bioguide_id = params[:captures].first
  office = Office.where("member.bioguide_id" => bioguide_id).first
  positions = Position.where("office.member.bioguide_id" => bioguide_id).order_by([["staffer.last_name", :asc], ["staffer.first_name", :asc]]).all
  
  if csv?
    office_to_csv office, positions
  else
    erb :office, :locals => {:office => office, :positions => positions}
  end
end

get '/committee/:committee_id' do
  office = Office.where("committee.id" => params[:committee_id]).first
  
  positions = Position.where("office.committee.id" => params[:committee_id]).order_by([["staffer.last_name", :asc], ["staffer.first_name", :asc]]).all
  
  if csv?
    office_to_csv office, positions
  else
    erb :office, :locals => {:office => office, :positions => positions}
  end
end


get '/members' do
  conditions = {}
  
  [:state, :district, :title].each do |key|
    if params[key]
      conditions["member.#{key}"] = params[key]
    end
  end
  
  offices = Office.members.house.where(conditions).order_by([["member.in_office", :desc], ["member.lastname", :asc], ["member.firstname", :asc]]).all
  
  if csv?
    members_to_csv offices
  else
    erb :offices, :locals => {:offices => offices, :type => 'members'}
  end
end

get '/committees' do
  offices = Office.committees.order_by([[:name, :asc]]).all
  
  if csv?
    committees_to_csv offices
  else
    erb :offices, :locals => {:offices => offices, :type => 'committees'}
  end
end

get '/offices' do
  offices = Office.others.order_by([[:name, :asc]]).all
  
  if csv?
    offices_to_csv offices
  else
    erb :offices, :locals => {:offices => offices, :type => 'offices'}
  end
end


def regex_for(value)
  regex_value = value.dup
  %w{+ ? . * ^ $ ( ) [ ] { } | \ }.each {|char| regex_value.gsub! char, "\\#{char}"}
  /#{regex_value}/i
end