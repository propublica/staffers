require 'mongoid/slug'

class Staffer
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  field :name
  field :original_names, :type => Array
  field :firstname_search
  field :lastname_search
  field :firstname
  field :lastname
  
  index :original_names
  index :firstname_search
  index :lastname_search
  index [[:lastname_search, Mongo::ASCENDING], [:firstname_search, Mongo::ASCENDING]]
  index :slug
  
  slug :name
  validates_uniqueness_of :slug
end

class Office
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  field :original_names, :type => Array
  field :name
  field :office_type
  
  index :original_names
  index :name
  index :type
  index :office_type
  index :slug
  
  slug :name
  validates_uniqueness_of :slug
  
  scope :legislators, :where => {:office_type => "member"}
  scope :committees, :where => {:office_type => "committee"}
  scope :other, :where => {:office_type => "other"}
end

class Title
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name
  field :original_names, :type => Array
  
  index :name
  index :original_names
  
  validates_uniqueness_of :name
end

class Quarter
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name
  index :name
  
  validates_uniqueness_of :name
end