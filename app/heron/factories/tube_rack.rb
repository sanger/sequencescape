# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class TubeRack
      include ActiveModel::Model

      include Concerns::CoordinatesSupport
      include Concerns::ForeignBarcodes
      include Concerns::RecipientsCoordinates
      include Concerns::Recipients
      include Concerns::Contents

      attr_accessor :sample_tubes, :tube_rack

      validates_presence_of :purpose, :purpose_uuid, :recipients

      def initialize(params)
        @params = params
      end

      def recipients_key
        :tubes
      end

      def recipient_factory
        ::Heron::Factories::Tube
      end

      def content_factory
        ::Heron::Factories::Sample
      end

      def barcode
        @params[:barcode]
      end

      delegate :size, to: :purpose

      def purpose_uuid
        @params[:purpose_uuid]
      end

      def purpose
        @purpose ||= ::TubeRack::Purpose.with_uuid(purpose_uuid).first
      end

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @tube_rack = ::TubeRack.create!(size:, purpose:)

          Barcode.create!(labware: tube_rack, barcode: barcode, format: barcode_format)

          create_recipients!
          create_contents!

          ::TubeRackStatus.create!(barcode: barcode, status: :created, labware: @tube_rack)
        end
        true
      end

      def sample_study_names
        return unless @tube_rack

        @tube_rack
          .tubes
          .each_with_object([]) do |tube, study_names|
            next if tube.aliquots.first.blank?

            study_names << tube.aliquots.first.study.name if tube.aliquots.first.study.present?
          end
          .uniq
      end

      private

      def create_recipients!
        @sample_tubes = create_tubes!(tube_rack)
      end

      def create_tubes!(tube_rack)
        recipients.keys.map do |coordinate|
          tube_factory = recipients[coordinate]
          sample_tube = tube_factory.create
          RackedTube.create(tube: sample_tube, coordinate: unpad_coordinate(coordinate), tube_rack: tube_rack)
        end
      end

      def create_contents!
        add_aliquots_into_locations(containers_for_locations)
      end

      def containers_for_locations
        @tube_rack
          .racked_tubes
          .each_with_object({}) do |racked_tube, memo|
            memo[unpad_coordinate(racked_tube.coordinate)] = racked_tube.tube.receptacle
          end
      end
    end
  end
end
