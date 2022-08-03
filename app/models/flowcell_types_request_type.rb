# frozen_string_literal: true
class FlowcellTypesRequestType < ApplicationRecord
  belongs_to :flowcell_type, inverse_of: :flowcell_types_request_types
  belongs_to :request_type, inverse_of: :flowcell_types_request_types
end
