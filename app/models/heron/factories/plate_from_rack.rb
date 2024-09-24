# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    class PlateFromRack
      include ActiveModel::Model

      attr_accessor :tube_rack, :plate, :plate_purpose

      validates :tube_rack, :plate_purpose, presence: true
      validate :check_tube_rack_persisted

      def save
        return false unless valid?

        ActiveRecord::Base.transaction do
          @plate = plate_purpose.create!
          ExtractionAttribute.create!(attributes_update: plate_contents, target: @plate, created_by: 'heron')

          AssetLink.create_edge(tube_rack, plate)
        end
        true
      end

      def plate_contents
        tube_rack.racked_tubes.map do |racked_tube|
          {}.tap do |obj|
            obj['location'] = racked_tube.coordinate
            obj['sample_tube_uuid'] = racked_tube.tube.uuid
          end
        end
      end

      private

      def check_tube_rack_persisted
        errors.add(:tube_rack, 'The tube rack is not in database yet') unless tube_rack.persisted?
      end
    end
  end
end
