class LibraryType < ApplicationRecord
  validates :name, presence: true

  scope :alphabetical, ->() { order(:name) }

  has_many :library_types_request_types, inverse_of: :library_type, dependent: :destroy
  has_many :request_types, through: :library_types_request_types
end
