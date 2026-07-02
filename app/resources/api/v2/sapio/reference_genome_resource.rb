# frozen_string_literal: true
module Api
  module V2
    module Sapio
      class ReferenceGenomeResource < Api::V2::BaseResource
        immutable
        # @!attribute [r] name
        #   @return [String] The name of the reference genome.
        attribute :name

        # @!attribute [r] uuid
        #   @return [String] The UUID of the reference genome.
        attribute :uuid

        # @!attribute [r] created_at
        #   @return [String] Timestamp when the reference genome was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String] Timestamp when the reference genome was last updated.
        attribute :updated_at
      end
    end
  end
end
