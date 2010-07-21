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
  staffers = []
  
  if params[:state].present? and params[:quarter].present?
    staffers = Staffer.all "quarters.#{params[:quarter]}.office.legislator.state" => params[:state]
  elsif params[:staffer_name].present?
    staffers = Staffer.all :lastname_search => params[:staffer_name].downcase
  elsif params[:title].present? and params[:quarter].present?
    staffers = Staffer.all "quarters.#{params[:quarter]}.title" => /#{params[:title]}/i
  elsif params[:legislator_name].present? and params[:quarter].present?
    staffers = Staffer.all "quarters.#{params[:quarter]}.office.legislator.lastname_search" => params[:legislator_name].downcase
  else
    staffers = nil
  end
  
  erb :search, :locals => {:staffers => staffers}
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