# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class TubeRack
      include ActiveModel::Model

      HERON_STUDY = 6187
      LOCATION_REGEXP = /[A-Z][0-9]{0,1}[0-9]/.freeze

      attr_accessor :barcode, :sample_tubes, :tube_rack, :size

      validates_presence_of :barcode, :tubes, :heron_study, :size, :purpose

      validate :check_tubes, :check_rack_barcode

      def heron_study
        @heron_study ||= Study.find(Heron::Factories::TubeRack::HERON_STUDY)
      end

      def tubes=(attributes)
        attributes.each do |tube|
          tubes[tube[:coordinate]] = ::Heron::Factories::Tube.new(tube.except(:coordinate).merge(study: heron_study))
        end
      end

      def racked_tubes
        @racked_tubes ||= []
      end

      def purpose
        @purpose ||= ::TubeRack::Purpose.where(target_type: 'TubeRack', size: size).first
      end

      def tubes
        @tubes ||= {}
      end

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @tube_rack = ::TubeRack.create!(size: size, purpose: purpose)

          Barcode.create!(asset: tube_rack, barcode: barcode, format: barcode_format)

          @sample_tubes = create_tubes!(tube_rack)
        end
        true
      end

      private

      def unpad_coordinate(coordinate)
        return coordinate unless coordinate

        loc = coordinate.match(/(\w)(0*)(\d*)/)
        loc[1] + loc[3]
      end

      def create_tubes!(tube_rack)
        tubes.keys.map do |coordinate|
          tube_factory = tubes[coordinate]
          sample_tube = tube_factory.create
          racked_tubes << RackedTube.create(tube: sample_tube, coordinate: unpad_coordinate(coordinate),
                                            tube_rack: tube_rack)
        end
      end

      def coordinate_valid?(coordinate)
        return false if coordinate.blank?

        coordinate.match?(::Heron::Factories::TubeRack::LOCATION_REGEXP)
      end

      def barcode_format
        Barcode.matching_barcode_format(barcode)
      end

      def check_rack_barcode
        if barcode_format.nil?
          error_message = "The tube rack barcode '#{barcode}' is not a recognised format."
          errors.add(:base, error_message)
          return false
        end
        true
      end

      def check_tubes
        tubes.keys.each do |coordinate|
          tube = tubes[coordinate]

          errors.add(:coordinate, 'Invalid coordinate format') unless coordinate_valid?(coordinate)

          next if tube.valid?

          tube.errors.each do |k, v|
            errors.add("Tube at #{coordinate} #{k}", v)
          end
        end
      end
    end
  end
end
