# frozen_string_literal: true

module Api
  module V2
    module Sapio
      class ProgramResource < Api::V2::BaseResource
        immutable

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String, nil] Study type name.
        attribute :name

        # @!attribute [r] created_at
        #   @return [String, nil] Timestamp when the study type was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String, nil] Timestamp when the study type was last updated.
        attribute :updated_at
      end
    end
  end
end
