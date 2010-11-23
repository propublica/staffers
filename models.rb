class Staffer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :original_names, :type => Array
  field :firstname_search, :type => String
  field :lastname_search, :type => String
  field :firstname, :type => String
  field :lastname, :type => String
  
  index :original_names
  index :firstname_search
  index :lastname_search
  index [[:lastname_search, Mongo::ASCENDING], [:firstname_search, Mongo::ASCENDING]]
  
  def name
    [firstname, lastname].join " "
  end
end

class Office
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :original_names, :type => Array
  field :bioguide_id, :type => String
  field :committee_id, :type => String
  field :name, :type => String
  field :office_type, :type => String
  
  index :original_names
  index :bioguide_id
  index :committee_id
  index :name
  index :type
end

class Title
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :original_names, :type => Array
  index :original_names
  
  field :name, :type => String
  index :name
end

class Quarter
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  
  index :name
end