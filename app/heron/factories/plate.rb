# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class Plate
      include ActiveModel::Model
      include Concerns::ForeignBarcodes

      attr_accessor :plate

      validate :plate_purpose_exists

      validate :validate_wells_content

      def initialize(params)
        @params = params
      end

      def barcode
        @params[:barcode]
      end

      def wells_content
        @wells_content ||= ::Heron::Factories::WellsContent.new(@params[:wells_content], @params[:study_uuid])
      end

      def validate_wells_content
        return if wells_content.valid?

        errors.add(:wells_content, wells_content.errors.full_messages)
      end

      def plate_purpose_exists
        unless @params.key?(:plate_purpose_uuid)
          errors.add(:base, 'Plate purpose uuid not defined')
          return
        end
        @plate_purpose ||= PlatePurpose.with_uuid(@params[:plate_purpose_uuid]).first
        errors.add(:base, "Plate purpose for uuid (#{@params[:plate_purpose_uuid]}) do not exist") unless @plate_purpose
      end

      attr_reader :plate_purpose

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @plate = plate_purpose.create!

          Barcode.create!(asset: @plate, barcode: barcode, format: barcode_format)

          wells_content.add_aliquots_into_plate(plate)
        end
        true
      end
    end
  end
end
