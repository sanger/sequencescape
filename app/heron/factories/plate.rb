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
      include Concerns::Eventful

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

      def save # rubocop:todo Metrics/MethodLength
        return false unless valid?

        @output_result = true
        ActiveRecord::Base.transaction do
          @plate = purpose.create!

          # Overriding labware=() function causes issues in the factory
          new_barcode = Barcode.new(barcode: barcode, format: barcode_format)
          new_barcode.labware(@plate)
          new_barcode.save!

          create_contents!

          if @params[:events]
            events = build_events(@plate)
            events.each do |event|
              rollback_for_events(events) unless event.valid?
              event.save
            end
          end
        end
        @output_result
      end

      def sample_study_names
        return unless @plate

        @plate
          .wells
          .each_with_object([]) do |well, study_names|
            next if well.aliquots.first.blank?

            study_names << well.aliquots.first.study.name if well.aliquots.first.study.present?
          end
          .uniq
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
        @plate.wells.index_by { |well| unpad_coordinate(well.map.description) }
      end
    end
  end
end
