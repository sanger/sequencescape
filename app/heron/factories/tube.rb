# frozen_string_literal: true

module Heron
  module Factories
    #
    # Factory class to generate sample tubes inside a Heron rack
    class Tube
      include ActiveModel::Model
      include Concerns::ForeignBarcodes

      attr_accessor :sample_tube

      ##
      # Persists the material including the associated container
      def create
        return unless valid?

        @sample_tube = SampleTube.create!
        Barcode.create!(asset_id: @sample_tube.id, barcode:, format: barcode_format)

        @sample_tube
      end
    end
  end
end
