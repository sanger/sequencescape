class LibraryTypesRequestType < ActiveRecord::Base

  belongs_to :library_type, :inverse_of => :library_types_request_types
  belongs_to :request_type, :inverse_of => :library_types_request_types

end
