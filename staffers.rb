#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'config/environment'

get '/' do
  erb :index, :locals => {:staffer => Staffer.first}
end


class Staffer
  include MongoMapper::Document
  
  key :first_name, String
  key :last_name, String
  
  def name
    "#{first_name} #{last_name}".strip
  end
end