# frozen_string_literal: true

FactoryBot.define do
  factory :lot_type do
    sequence(:name) { |n| "lot_type#{n}" }
    template_class { 'PlateTemplate' }
    target_purpose { Tube::Purpose.stock_library_tube }

    factory :tag2_lot_type do
      template_class { 'Tag2LayoutTemplate' }
    end

    factory :tag_layout_lot_type do
      sequence(:name) { |n| "'Pre Stamped Tags - 384 - #{n}" }
      template_class { 'TagLayoutTemplate' }
      target_purpose { create(:tag_layout_qcable_plate_purpose) }
    end
  end

  factory :pending_purpose, parent: :tube_purpose do
    name { FactoryBot.generate(:purpose_name) }
    default_state { 'pending' }
  end

  factory :created_purpose, parent: :tube_purpose do
    name { FactoryBot.generate(:purpose_name) }
    default_state { 'created' }
  end

  factory :qcable_creator do
    count { 0 }
    user
    lot
  end

  factory :lot do
    sequence(:lot_number) { |n| "lot#{n}" }
    lot_type
    template factory: %i[plate_template_with_well]
    user
    received_at { '2014-02-01' }

    factory :tag2_lot do
      lot_type factory: %i[tag2_lot_type]
      template factory: %i[tag2_layout_template]
    end

    factory :tag_layout_lot do
      lot_type factory: %i[tag_layout_lot_type]
      template factory: %i[tag_layout_template]
    end
  end

  factory :stamp do
    lot
    user
    robot
    tip_lot { '555' }
  end

  factory :qcable do
    # NOTE: We don't use the automatic association building here as
    # we rely on attributes_for, which doesn't seem to handle it well.
    # Incidentally we use attributes_for here as factory_bot instantiates
    # the object before setting attributes, which messes up the state machine
    # callbacks.
    lot { create(:lot) }
    qcable_creator { create(:qcable_creator) }
    transient { sanger_barcode { create(:sanger_ean13) } }

    factory :qcable_with_asset do
      state { 'created' }
      asset { create(:full_plate, sanger_barcode:) }
    end
  end

  factory :plate_template_with_well, class: 'PlateTemplate' do
    sequence(:name) { |n| "testtemplate#{n}" }
    size { 96 }
    wells { [create(:well_with_sample_and_without_plate, map: create(:map))] }
  end

  factory :tag_layout_qcable_plate_purpose, class: 'QcablePlatePurpose' do
    sequence(:name) { |n| "Tag Plate - 384 - #{n}" }
    target_type { 'Plate' }
  end
end
