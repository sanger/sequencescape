# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron wells content in a plate
    class WellsContent
      include ActiveModel::Model
      include Concerns::CoordinatesSupport

      validate :sample_factories

      def initialize(params)
        @params = params
      end

      def sample_factories
        return [] unless @params

        @sample_factories ||= @params.keys.each_with_object({}) do |location, memo|
          errors.add(:coordinate, 'Invalid coordinate format') unless coordinate_valid?(location)

          samples_params = [@params[location]].flatten
          memo[location] = samples_params.map do |sample_params|
            factory = ::Heron::Factories::Sample.new(sample_params)
            errors.add(:sample, factory.errors) unless factory.valid?
            factory
          end
        end
      end

      def add_aliquots_into_plate(plate)
        return false unless valid?

        sample_factories.each do |location, factories|
          well_at_location = plate.wells.located_at(unpad_coordinate(location)).first
          factories.each do |factory|
            factory.create_aliquot_at(well_at_location) if factory.valid?
          end
        end
        true
      end
    end
  end
end
