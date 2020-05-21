# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class Plate
      include ActiveModel::Model
      include Concerns::ForeignBarcodes
      include Concerns::CoordinatesSupport
      include Concerns::RecipientsCoordinates
      include Concerns::Contents

      attr_accessor :plate, :purpose

      validate :purpose_exists

      def initialize(params)
        @params = params
      end

      def recipients_key
        :wells
      end

      def content_factory
        ::Heron::Factories::Sample
      end

      def barcode
        @params[:barcode]
      end

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @plate = purpose.create!

          Barcode.create!(asset: @plate, barcode: barcode, format: barcode_format)

          create_contents!
        end
        true
      end

      private

      def create_contents!
        add_aliquots_into_locations(containers_for_locations)
      end

      def purpose_exists
        unless @params.key?(:purpose_uuid)
          errors.add(:base, 'Plate purpose uuid not defined')
          return
        end
        @purpose ||= PlatePurpose.with_uuid(@params[:purpose_uuid]).first
        errors.add(:base, "Plate purpose for uuid (#{@params[:purpose_uuid]}) do not exist") unless @purpose
      end

      def containers_for_locations
        @plate.wells.each_with_object({}) do |well, memo|
          memo[unpad_coordinate(well.map.description)] = well
        end
      end
    end
  end
end
