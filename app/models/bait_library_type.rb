class BaitLibraryType < ActiveRecord::Base
  has_many :bait_library
  
  # Types have names, need to be unique
  validates_presence_of :name
  validates_uniqueness_of :name
end
