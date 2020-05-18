# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class TubeRack
      include ActiveModel::Model

      include Concerns::HeronStudy
      include Concerns::CoordinatesSupport
      include Concerns::ForeignBarcodes

      attr_accessor :sample_tubes, :tube_rack

      validates_presence_of :size, :purpose, :tubes
      validate :check_tubes, if: :tubes
      validate :check_tubes_content, if: :tubes_content

      def initialize(params)
        @params = params
      end

      def barcode
        @params[:barcode]
      end

      def size
        @params[:size]
      end

      def tubes
        return nil unless @params[:tubes]

        @tubes ||= @params[:tubes].keys.each_with_object({}) do |coordinate, memo|
          container_attrs = @params[:tubes][coordinate].dig(:container) || {}
          memo[coordinate] = ::Heron::Factories::Tube.new(container_attrs)
        end
      end

      def tubes_content
        return unless @params[:tubes]

        @tubes_content ||= ::Heron::Factories::Content.new(params_for_content, @params[:study_uuid])
      end

      def racked_tubes
        @racked_tubes ||= []
      end

      def purpose
        @purpose ||= ::TubeRack::Purpose.where(target_type: 'TubeRack', size: size).first
      end

      def params_for_content
        @params_for_content ||= @params[:tubes].keys.each_with_object({}) do |location, memo|
          obj = @params[:tubes][location]
          memo[location] = @params[:tubes][location].except(:container) if obj
        end
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
        @tube_rack.racked_tubes.each_with_object({}) do |racked_tube, memo|
          memo[unpad_coordinate(racked_tube.coordinate)] = racked_tube.tube
        end
      end

      def create_contents!
        tubes_content.add_aliquots_into_locations(containers_for_locations)
      end

      def create_tubes!(tube_rack)
        tubes.keys.map do |coordinate|
          tube_factory = tubes[coordinate]
          sample_tube = tube_factory.create
          racked_tubes << RackedTube.create(tube: sample_tube, coordinate: unpad_coordinate(coordinate),
                                            tube_rack: tube_rack)
        end
      end

      def check_tubes_content
        return if tubes_content.valid?

        errors.add(:tubes_content, tubes_content.errors.full_messages)
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
