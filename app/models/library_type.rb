# frozen_string_literal: true

# A library type is an identifier which describes how a library has been produced
# Whereas {RequestType} is largely internal to sequencescape, a library type directly
# reflects the science, and thus has a many to many relationship with request type.
# LibraryType gets exposed in the multi-lims warehouse, and can affect downstream
# processing.
#
# Some library types have no request type associated. These may be used by
# external pipelines, such as Traction, or may be of use exclusively for library
# manifests.
#
# @note For historical reasons, library type is *not* a relationship on request_metadata
# or on aliquot. This is because library_types used to by hardcoded in the {Request}
# class.
class LibraryType < ApplicationRecord
  include SharedBehaviour::Named

  scope :long_read, -> { alphabetical.where(name: records_in('001_long_read')) }

  has_many :library_types_request_types, inverse_of: :library_type, dependent: :destroy
  has_many :request_types, through: :library_types_request_types

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.records_in(file_name)
    RecordLoader::LibraryTypeLoader.new(files: [file_name]).names
  end
end
