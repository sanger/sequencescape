# frozen_string_literal: true
class LibraryTypesRequestType < ApplicationRecord
  belongs_to :library_type, inverse_of: :library_types_request_types
  belongs_to :request_type, inverse_of: :library_types_request_types
end
