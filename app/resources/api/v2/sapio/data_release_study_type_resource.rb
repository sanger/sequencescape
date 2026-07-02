# frozen_string_literal: true
module Api
  module V2
    module Sapio
      class DataReleaseStudyTypeResource < Api::V2::BaseResource
        immutable

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String, nil] Name of the data release study type.
        attribute :name

        # @!attribute [r] created_at
        #   @return [String, nil] Timestamp when the data release study type was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String, nil] Timestamp when the data release study type was last updated.
        attribute :updated_at

        # @!attribute [r] for_array_express
        #   @return [Boolean, nil] Whether this study type is for ArrayExpress workflows.
        attribute :for_array_express

        # @!attribute [r] is_default
        #   @return [Boolean, nil] Whether this is the default data release study type.
        attribute :is_default

        # @!attribute [r] is_assay_type
        #   @return [Boolean, nil] Whether this is an assay-type study type.
        attribute :is_assay_type
      end
    end
  end
end
