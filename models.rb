require 'mongoid/slug'

class Position
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # finding all positions by an office or staffer
  index "office.slug"
  index "staffer.slug"
  
  # various search form options
  index :title
  index "office.member.state"
  index "office.member.party"
  index "office.member.chamber"
  index "staffer.first_name"
  index "staffer.last_name"
end

class Staffer
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  slug :name
  validates_uniqueness_of :slug
  index :slug
  
  field :name
  field :original_names, :type => Array
  field :first_name
  field :last_name
  
  index :original_names
  index [[:last_name, Mongo::ASCENDING], [:first_name, Mongo::ASCENDING]]

  # scope :alphabetical, 
end

class Office
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  index :slug
  slug :name
  validates_uniqueness_of :slug
  
  field :original_names, :type => Array
  field :name
  field :office_type
  field :chamber
  
  index :original_names
  index :chamber
  index :name
  index :office_type
  
  index "committee.id"
  index "member.bioguide_id"
  
  
  scope :members, :where => {:office_type => "member"}
  scope :committees, :where => {:office_type => "committee"}
  scope :others, :where => {:office_type => "other"}
  
  scope :house, :where => {:chamber => 'house'}
  scope :senate, :where => {:chamber => 'senate'}
  
  def member?
    office_type == 'member'
  end
  
  def committee?
    office_type == 'committee'
  end
  
  def other?
    office_type == 'other'
  end
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