FactoryGirl.define do
  factory :plate_with_wells, parent: :plate do
    size 96
    after(:create) do |plate|
      plate.wells = Map.where_description(%w(A1 B1 C1 D1 E1 F1 G1 H1))
                       .where_plate_size(plate.size)
                       .where_plate_shape(AssetShape.default).map do |map|
              build(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
      end
    end
  end

  factory :lib_pcr_xp_plate, parent: :plate do
    size 96
    plate_purpose { |_| PlatePurpose.find_by(name: 'Lib PCR-XP') }

    after(:create) do |plate|
      plate.wells = Map.where_description(%w(A1 B1 C1 D1 E1 F1 G1 H1))
                       .where_plate_size(plate.size)
                       .where_plate_shape(AssetShape.default).map do |map|
              build(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
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
    asset_type 'Well'
    request_class CustomerRequest
    key 'Illumina_Lib_PCR_XP_Lib_Pool'
  end

  factory :illumina_htp_mx_tube_purpose, class: IlluminaHtp::MxTubePurpose do
    sequence(:name) { |n| "Illumina HTP Mx Tube Purpose #{n}" }
    target_type 'MultiplexedLibraryTube'
  end

  factory :lib_pcr_xp_tube, class: MultiplexedLibraryTube do
    name { |_a| FactoryGirl.generate :asset_name }
    association(:purpose, factory: :illumina_htp_mx_tube_purpose)
    after(:create) { |tube| create(:transfer_request, asset: create(:lib_pcr_xp_well_with_sample_and_plate), target_asset: tube) }
  end

  factory :lib_pcr_xp_well_with_sample_and_plate, parent: :well_with_sample_and_without_plate do
    map
    plate { |plate| plate.association(:lib_pcr_xp_child_plate) }
  end
end
