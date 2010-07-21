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
  elsif params[:legislator_name].present? and params[:quarter].present?
    staffers = Staffer.all "quarters.#{params[:quarter]}.office.legislator.lastname_search" => params[:legislator_name].downcase
  else
    staffers = nil
  end
  
  erb :search, :locals => {:staffers => staffers, :quarter => params[:quarter]}
end

get '/staffer/:id' do
  staffer = Staffer.first :_id => params[:id]
  
  erb :staffer, :locals => {:staffer => staffer}
end