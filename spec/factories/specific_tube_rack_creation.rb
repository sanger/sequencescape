# frozen_string_literal: true

FactoryBot.define do
  factory(:specific_tube_rack_creation) do
    # tube_rack_attributes should be set in your specific test, as the purposes
    # need to exist for creation to work.
    # NB. You can have multiple tuberacks with multiple racked tubes.
    # Racks and tubes can have different purposes for flexibility.
    # Example:
    # [
    #   {
    #     tube_rack_name: 'Tube Rack',
    #     tube_rack_barcode: 'TR00000001',
    #     tube_rack_purpose_uuid: 'example-tube-rack-purpose-uuid',
    #     tube_rack_metadata_key: 'tube_rack_barcode',
    #     racked_tubes: [
    #       {
    #         tube_barcode: 'ST00000001',
    #         tube_name: 'SEQ:NT1A:A1',
    #         tube_purpose_uuid: 'example-seq-tube-purpose-uuid',
    #         tube_position: 'A1',
    #         parent_uuids: ['example-parent-well-1-uuid']
    #       },
    #       {
    #         tube_barcode: 'ST00000002',
    #         tube_name: 'SEQ:NT2B:B1',
    #         tube_purpose_uuid: 'example-seq-tube-purpose-uuid',
    #         tube_position: 'B1',
    #         parent_uuids: ['example-parent-well-2-uuid']
    #       }
    #     ]
    #   }
    # ]
    tube_rack_attributes { [] }
    user { |target| target.association(:user) }

    parents { |target| [target.association(:plate)] }
  end
end
