# frozen_string_literal: true

require './lib/record_loader/library_type_loader'

# Requested flowcell types for DPL-417
class FlowcellType < ApplicationRecord
  include SharedBehaviour::Named

  scope :from_record_loaders, ->(loader) { alphabetical.where(name: records_in(loader)) }

  has_many :flowcell_types_request_types, inverse_of: :flowcell_type, dependent: :destroy
  has_many :request_types, through: :flowcell_types_request_types

  validates :requested_flowcell_type, presence: true

  def self.records_in(file_name)
    RecordLoader::FlowcellTypeLoader.new(files: [file_name]).names
  end
end
