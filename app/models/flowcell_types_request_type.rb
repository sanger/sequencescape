# frozen_string_literal: true

# This class contains the relation between a type of flowcell and a request type
# where that flowcell could be used
class FlowcellTypesRequestType < ApplicationRecord
  belongs_to :flowcell_type, inverse_of: :flowcell_types_request_types
  belongs_to :request_type, inverse_of: :flowcell_types_request_types
end
