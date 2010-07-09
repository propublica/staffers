#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'config/environment'

get '/' do
  erb :index, :locals => {:staffer => Staffer.first}
end


class Staffer
  include MongoMapper::Document
  
  # original unstandardized name, used as unique key
  key :name_original, String, :index => true
  
  # basic info
  key :firstname, String, :index => true
  key :lastname, String, :index => true
  
  def display_name
    "#{first_name} #{last_name}".strip
  end
end

class Office
  include MongoMapper::Document
  
  key :bioguide_id, String, :index => true
  key :committee_id, String, :index => true
  key :name, String, :index => true
  key :type, String, :index => true
  
end