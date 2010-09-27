class Staffer
  include MongoMapper::Document
  
  # original unstandardized name, used as unique key
  key :name_original, String, :index => true
  
  # basic info
  key :firstname_search, String, :index => true
  key :lastname_search, String, :index => true
  
  ensure_index [[:lastname_search, 1], [:firstname_search, 1]]
  
  key :firstname, String
  key :lastname, String
end

class Office
  include MongoMapper::Document
  
  key :bioguide_id, String, :index => true
  key :committee_id, String, :index => true
  key :name, String, :index => true
  key :type, String, :index => true
end

class Title
  include MongoMapper::Document
  
  key :name, String, :index => true
end

class Quarter
  include MongoMapper::Document
  
  key :name, String, :index => true
end