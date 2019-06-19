# frozen_string_literal: true

FactoryBot.define do
  factory :plate_with_3_wells, parent: :plate do
    size { 96 }
    after(:create) do |plate|
      plate.wells = Map.where_description(%w[A1 B2 E6])
                       .where_plate_size(plate.size)
                       .where_plate_shape(AssetShape.default).map do |map|
        build(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
      end
      plate.wells.each do |well|
        well.well_attribute.current_volume = 160
        well.save
      end
    end
  end

  factory :lib_pcr_xp_plate, parent: :plate do
    size { 96 }
    plate_purpose { |_| PlatePurpose.find_by(name: 'Lib PCR-XP') }

    after(:create) do |plate|
      plate.wells = Map.where_description(%w[A1 B1 C1])
                       .where_plate_size(plate.size)
                       .where_plate_shape(AssetShape.default).map do |map|
        reqs = create(:lib_pcr_xp_request)
        plate.children << reqs.target_asset
        build(:tagged_well, map: map, requests: [reqs])
      end
    end
  end

  factory :lib_pcr_xp_plate_with_tubes, parent: :plate do
    size { 96 }
    plate_purpose

    after(:create) do |plate|
      plate.wells = Map.where_description(%w[A1 B1 C1])
                       .where_plate_size(plate.size)
                       .where_plate_shape(AssetShape.default).map do |map|
        tube = create(:lib_pool_tube)
        plate.children << tube
        build(:tagged_well, map: map).tap do |well|
          create(:lib_pcr_xp_request, asset: well, target_asset: tube)
        end
      end
    end
  end

  factory :lib_pcr_xp_child_plate, parent: :plate do
    transient do
      parent { create(:lib_pcr_xp_plate) }
    end

    after(:create) do |child_plate, evaluator|
      child_plate.parents << evaluator.parent
      child_plate.purpose.source_purpose = evaluator.parent.purpose
    end
  end

  factory :lib_pcr_xp_request_type, parent: :request_type do
    asset_type { 'Well' }
    request_class { CustomerRequest }
    key { 'Illumina_Lib_PCR_XP_Lib_Pool' }
  end

  factory :lib_pool_tube, class: StockMultiplexedLibraryTube do
    name { |_a| FactoryBot.generate :asset_name }
    association(:purpose, factory: :illumina_htp_initial_stock_tube_purpose)
    after(:create) { |tube| create(:transfer_request, target_asset: tube) }
  end

  factory :lib_pool_norm_tube, class: MultiplexedLibraryTube do
    transient do
      parent_tube { create :lib_pool_tube }
    end
    name { generate :asset_name }
    association(:purpose, factory: :illumina_htp_mx_tube_purpose)
    after(:create) { |tube, factory| create(:transfer_request, asset: factory.parent_tube, target_asset: tube) }
  end

  factory :lib_pcr_xp_well_with_sample_and_plate, parent: :well_with_sample_and_without_plate do
    map
    plate { |plate| plate.association(:lib_pcr_xp_child_plate) }
  end
end
