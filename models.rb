class Staffer
  include MongoMapper::Document
  
  # original unstandardized names, used as a locator
  key :original_names, Array, :index => true
  
  # basic info
  key :firstname_search, String, :index => true
  key :lastname_search, String, :index => true
  
  key :firstname, String
  key :lastname, String
  
  ensure_index [[:lastname_search, 1], [:firstname_search, 1]]
  
  def name
    [firstname, lastname].join " "
  end
end

class Office
  include MongoMapper::Document
  
  # original unstandardized names, used as a locator
  key :original_names, Array, :index => true
  
  key :bioguide_id, String, :index => true
  key :committee_id, String, :index => true
  key :name, String, :index => true
  key :type, String, :index => true
end

class Title
  include MongoMapper::Document
  
  # original unstandardized names, used as a locator
  key :original_names, Array, :index => true
  
  key :name, String, :index => true
end

class Quarter
  include MongoMapper::Document
  
  key :name, String, :index => true
end