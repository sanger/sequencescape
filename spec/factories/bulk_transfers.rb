# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_transfer do
    transient do
      source_plates { create_list(:plate, 2) }
      destination_plates { create_list(:plate, 2) }
    end

    user
    well_transfers do
      [
        {
          'source_uuid' => source_plates[0].uuid,
          'source_location' => 'A1',
          'destination_uuid' => destination_plates[0].uuid,
          'destination_location' => 'A1'
        },
        {
          'source_uuid' => source_plates[0].uuid,
          'source_location' => 'B1',
          'destination_uuid' => destination_plates[1].uuid,
          'destination_location' => 'A1'
        },
        {
          'source_uuid' => source_plates[1].uuid,
          'source_location' => 'A1',
          'destination_uuid' => destination_plates[0].uuid,
          'destination_location' => 'B1'
        },
        {
          'source_uuid' => source_plates[1].uuid,
          'source_location' => 'B1',
          'destination_uuid' => destination_plates[1].uuid,
          'destination_location' => 'B1'
        }
      ]
    end
  end
end
