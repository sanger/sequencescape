module Heron
  module Factories
    class TubeRack
      include ActiveModel::Model

      HERON_STUDY = 6187
      LOCATION_REGEXP = /[A-Z][0-9]{0,1}[0-9]/
      RACK_SIZE = 96

      attr_accessor :barcode, :sample_tubes, :tube_rack

      validates_presence_of :barcode, :tubes

      validate :check_tubes, :check_rack_barcode

      def heron_study
        @heron_study ||= Study.find(Heron::Factories::TubeRack::HERON_STUDY)
      end

      def tubes=(attributes)
        attributes.each do |tube|
          tubes[tube[:location]] = ::Heron::Factories::Tube.new(tube.except(:location).merge(study: heron_study))
        end
      end

      def racked_tubes
        @racked_tubes ||= []
      end

      def tubes
        @tubes ||= {}
      end

      def save
        return false unless valid?
        ActiveRecord::Base.transaction do
          purpose = Purpose.where(target_type: 'TubeRack', size: ::Heron::Factories::TubeRack::RACK_SIZE).first
          tube_rack = ::TubeRack.create!(size: ::Heron::Factories::TubeRack::RACK_SIZE, plate_purpose_id: purpose&.id)

          Barcode.create!(asset: tube_rack, barcode: barcode, format: barcode_format)

          @sample_tubes = create_tubes!(tube_rack)
        end
        true
      end

      private

      def create_tubes!(tube_rack)
        tubes.keys.map do |location|
          tube_factory = tubes[location]
          sample_tube = tube_factory.create
          racked_tubes << RackedTube.create(tube: sample_tube, coordinate: location,
            tube_rack: tube_rack)
        end
      end

      def location_valid?(location)
        return false unless location.present?
        location.match?(::Heron::Factories::TubeRack::LOCATION_REGEXP)
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
        tubes.keys.each do |location|
          tube = tubes[location]

          unless location_valid?(location)
            errors.add(:location, 'Invalid location format')
          end

          unless tube.valid?
            tube.errors.each do |k, v|
              errors.add("Tube at #{location} #{k}", v)
            end
          end
        end
      end

    end
  end
end
