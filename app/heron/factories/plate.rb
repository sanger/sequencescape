# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class Plate
      include ActiveModel::Model
      
      include Concerns::CoordinatesSupport
      include Concerns::ForeignBarcodes

      attr_accessor :plate

      validates_presence_of :study, :plate_purpose
      validate :check_valid_samples_information

      def initialize(params)
        @params = params
      end

      def barcode
        @params[:barcode]
      end

      def check_valid_samples_information
        return if sample_factories.empty?

        return if sample_factories.values.flatten.all?(&:valid?)

        sample_factories.each do |k, factories|
          factories.each do |factory|
            errors.add(k, factory.errors)
          end
        end
      end

      def sample_factories
        return [] unless @params[:wells_content]

        @sample_factories ||= @params[:wells_content].keys.each_with_object({}) do |location, memo|
          samples_params = [@params[:wells_content][location]].flatten
          memo[location] = samples_params.map do |sample_params|
            ::Heron::Factories::Sample.new(sample_params.merge(study: study))
          end
        end
      end

      def study
        @study ||= @params[:study] || Study.with_uuid(@params[:study_uuid]).first
      end

      def plate_purpose
        @plate_purpose ||= @params[:plate_purpose] || PlatePurpose.with_uuid(@params[:plate_purpose_uuid]).first
      end

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @plate = plate_purpose.create!(params_for_plate_creation)

          Barcode.create!(asset: @plate, barcode: barcode, format: barcode_format)

          create_samples!(plate)
        end
        true
      end

      def create_samples!(plate)
        sample_factories.each do |location, factories|
          well_at_location = plate.wells.located_at(unpad_coordinate(location)).first
          factories.each do |factory|
            factory.create_aliquot_at(well_at_location) if factory.valid?
          end
        end
      end

      def params_for_plate_creation
        @params.except(:study, :study_uuid, :plate_purpose, :plate_purpose_uuid, :wells_content, :barcode)
      end

    end
  end
end
