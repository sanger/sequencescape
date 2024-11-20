# frozen_string_literal: true

FactoryBot.define do
  factory(:specific_tube_rack_creation) do
    transient do
      tube_rack_purpose { create(:tube_rack_purpose) }
      tube_purpose { create(:tube_purpose) }
      parent_plate { create(:plate) }
    end

    tube_rack_attributes do
      [
        {
          tube_rack_name: 'Tube Rack',
          tube_rack_barcode: 'TR00000001',
          tube_rack_purpose_uuid: tube_rack_purpose.uuid,
          racked_tubes: [
            {
              tube_barcode: 'ST00000001',
              tube_name: 'SEQ:NT1A:A1',
              tube_purpose_uuid: tube_purpose.uuid,
              tube_position: 'A1',
              parent_uuids: [parent_plate.wells.first.uuid]
            }
          ]
        }
      ]
    end

    user { |target| target.association(:user) }

    parents { |target| [target.association(:parent_plate)] }
  end
end
