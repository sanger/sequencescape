# frozen_string_literal: true

require './lib/record_loader/library_type_loader'

# Requested flowcell types for DPL-417
class FlowcellType < ApplicationRecord
  include SharedBehaviour::Named

  has_many :flowcell_types_request_types, inverse_of: :flowcell_type, dependent: :destroy
  has_many :request_types, through: :flowcell_types_request_types

  validates :requested_flowcell_type, presence: true
end
