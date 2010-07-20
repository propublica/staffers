#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'config/environment'

require 'models'
require 'helpers'

get '/' do
  erb :index
end

post '/staffers' do
  staffers = []
  
  if params[:state]
    staffers = Staffer.all "quarters.#{params[:quarter]}.office.legislator.state" => params[:state]
  end
  
  erb :search, :locals => {:staffers => staffers, :quarter => params[:quarter]}
end

get '/staffer/:id' do
  staffer = Staffer.first :_id => params[:id]
  
  erb :staffer, :locals => {:staffer => staffer}
end