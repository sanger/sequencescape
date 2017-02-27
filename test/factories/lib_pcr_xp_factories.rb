FactoryGirl.define do
  factory :plate_with_wells, parent: :plate do
    size 96
    after(:create) do |plate|
      plate.wells.import(
        %w(A1 B1 C1 D1 E1 F1 G1 H1).map do |location|
          map = Map.where_description(location)
            .where_plate_size(plate.size)
            .where_plate_shape(AssetShape.default).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
        end
      )
    end
  end

  factory :plate_with_3_wells, parent: :plate do
    size 96
    after(:create) do |plate|
      plate.wells.import(
        %w(A1 B2 E6).map do |location|
          map = Map.where_description(location)
            .where_plate_size(plate.size)
            .where_plate_shape(AssetShape.default).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
        end
      )
      plate.wells.each do |well|
        well.well_attribute.current_volume = 160
        well.save
      end
    end
  end

  factory :lib_pcr_xp_plate, parent: :plate do
    size 96
    plate_purpose { |_| PlatePurpose.find_by(name: 'Lib PCR-XP') }

    after(:create) do |plate|
      plate.wells.import(
        %w(A1 B1 C1 D1 E1 F1 G1 H1).map do |location|
          map = Map.where_description(location)
            .where_plate_size(plate.size)
            .where_plate_shape(AssetShape.default).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
          create(:tagged_well, map: map, requests: [create(:lib_pcr_xp_request)])
        end
      )
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
  end

  factory :lib_pcr_xp_tube, class: LibraryTube do
    name    { |_a| FactoryGirl.generate :asset_name }
    purpose { create(:illumina_htp_mx_tube_purpose) }
    after(:create) { |tube| create(:transfer_request, asset: create(:lib_pcr_xp_well_with_sample_and_plate), target_asset: tube) }
  end

  factory :lib_pcr_xp_well_with_sample_and_plate, parent: :well_with_sample_and_without_plate do |_well|
    map
    plate { |plate| plate.association(:lib_pcr_xp_child_plate) }
  end
end
