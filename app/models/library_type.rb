class LibraryType < ActiveRecord::Base

  validates_presence_of :name

  has_many :library_types_request_types, :inverse_of=> :library_type
  has_many :request_types, :through => :library_types_request_types

end
