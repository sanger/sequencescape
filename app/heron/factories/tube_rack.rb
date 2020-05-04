# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class TubeRack
      include ActiveModel::Model

      include Concerns::HeronStudy
      include Concerns::CoordinatesSupport
      include Concerns::ForeignBarcodes

      attr_accessor :sample_tubes, :tube_rack, :size

      validates_presence_of :tubes, :size, :purpose
      validate :check_tubes

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

          ::TubeRackStatus.create!(
            barcode: barcode,
            status: :created,
            labware: @tube_rack
          )
        end
        true
      end

      private

      def create_tubes!(tube_rack)
        tubes.keys.map do |coordinate|
          tube_factory = tubes[coordinate]
          sample_tube = tube_factory.create
          racked_tubes << RackedTube.create(tube: sample_tube, coordinate: unpad_coordinate(coordinate),
                                            tube_rack: tube_rack)
        end
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
