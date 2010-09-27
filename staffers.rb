#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'config/environment'

require 'models'
require 'helpers'

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
    staffers = Staffer.all search.merge(:order => "lastname_search ASC, firstname_search ASC")
  end
  
  erb :search, :locals => {:staffers => staffers, :quarter => params[:quarter]}
end

get '/staffer/:id' do
  staffer = Staffer.first :_id => params[:id]
  
  erb :staffer, :locals => {:staffer => staffer}
end

get '/office/:id' do
  office = Office.first :_id => params[:id]
  
  quarters = {}
  Quarter.all.each do |quarter|
    quarters[quarter.name] = Staffer.all "quarters.#{quarter.name}.office._id" => office._id, :order => "lastname_search ASC, firstname_search ASC"
  end
  
  erb :office, :locals => {:office => office, :quarters => quarters}
end

get '/offices' do
  offices = nil
  
  if params[:type] == 'member'
    offices = Office.all :type => 'member', :order => "legislator.lastname ASC, legislator.firstname ASC"
  elsif params[:type] == 'committee'
    offices = Office.all :type => 'committee', :order => "name ASC"
  elsif params[:type] == 'other'
    offices = Office.all :type => 'other', :order => "name ASC"
  end
  
  erb :offices, :locals => {:offices => offices, :type => params[:type]}
end