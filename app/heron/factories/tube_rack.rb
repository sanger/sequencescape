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

      validate :validate_tubes_content

      def initialize(params)
        @params = params
        tubes=@params[:tubes]
      end

      def tubes_content
        @tubes_content ||= ::Heron::Factories::Content.new(params_for_content, @params[:study_uuid])
      end

      def params_for_content
        return {} unless @params[:tubes].to_h
        @params[:tubes].to_h.reduce({}) do |memo, location|
          obj = @params[:tubes][location]
          memo[location] = @params[:tubes][location].except(:container) if obj
          memo
        end
      end

      def validate_tubes_content
        return if tubes_content.valid?

        errors.add(:tubes_content, tubes_content.errors.full_messages)
      end

      def tubes=(attributes)
        attributes.each do |coordinate|
          container_attrs = attributes[coordinate].dig(:container, {}).merge(study: heron_study)
          tubes[coordinate] = ::Heron::Factories::Tube.new(container_attrs)
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
          create_containers!
          create_contents!
          ::TubeRackStatus.create!(
            barcode: barcode,
            status: :created,
            labware: @tube_rack
          )
        end
        true
      end


      private

      def create_containers!
        @tube_rack = ::TubeRack.create!(size: size, purpose: purpose)

        Barcode.create!(asset: tube_rack, barcode: barcode, format: barcode_format)

        @sample_tubes = create_tubes!(tube_rack)
      end

      def containers_for_locations
        @tube_rack.racked_tubes.reduce({}) do |racked_tube|
          memo[unpad_coordinate(racked_tube.coordinate)] = racked_tube.tube
          memo
        end
      end

      def create_contents!          
        tubes_contents.add_aliquots_into_locations(containers_for_locations)
      end

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
