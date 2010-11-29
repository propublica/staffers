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
  
  def positions_for(quarter, office)
    quarters[quarter].select do |position|
      if office.member? and position['office']['legislator']
        position['office']['legislator']['bioguide_id'] == office['legislator']['bioguide_id']
      elsif office.committee? and position['office']['committee']
        position['office']['committee']['id'] == office['committee']['id']
      elsif office.other?
        position['office']['slug'] == office['slug']
      else
        false
      end
    end
  end
end

class Office
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  field :original_names, :type => Array
  field :name
  field :office_type
  field :chamber
  
  index :original_names
  index :chamber
  index :name
  index :type
  index :office_type
  index :slug
  
  slug :name
  validates_uniqueness_of :slug
  
  scope :legislators, :where => {:office_type => "member"}
  scope :committees, :where => {:office_type => "committee"}
  scope :other, :where => {:office_type => "other"}
  
  scope :house, :where => {:chamber => 'house'}
  scope :senate, :where => {:chamber => 'senate'}
  
  def member?
    office_type == 'member'
  end
  
  def legislator?
    member?
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