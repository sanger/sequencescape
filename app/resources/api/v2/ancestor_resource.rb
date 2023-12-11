# frozen_string_literal: true
module Api
  module V2
    class AncestorResource < LabwareResource
      filter :purpose_name
    end
  end
end
