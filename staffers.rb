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
  
  if params[:staffer_firstname].present?
    search[:firstname_search] = /#{params[:staffer_firstname]}/i
    search["quarters.#{params[:quarter]}"] = {"$exists" => true}
  end
  
  if params[:staffer_lastname].present?
    search[:lastname_search] = /#{params[:staffer_lastname]}/i
    search["quarters.#{params[:quarter]}"] = {"$exists" => true}
  end
  
  if params[:title].present?
    search["quarters.#{params[:quarter]}.title"] = /#{params[:title]}/i
  end

  if params[:state].present?
    search["quarters.#{params[:quarter]}.office.legislator.state"] = params[:state]
  end
  
  if params[:party].present?
    search["quarters.#{params[:quarter]}.office.legislator.party"] = params[:party]
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