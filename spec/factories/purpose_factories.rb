# frozen_string_literal: true

FactoryBot.define do
  factory :purpose do
    prefix { 'DN' }
    name { generate :purpose_name }
    target_type { 'Asset' }

    factory :stock_purpose do
      stock_plate { true }

      factory :illumina_c_stock_purpose, class: IlluminaC::StockPurpose do
      end
    end

    factory(:new_stock_tube_purpose, class: IlluminaHtp::StockTubePurpose) do
      target_type { 'StockMultiplexedLibraryTube' }

      factory :illumina_htp_initial_stock_tube_purpose, class: IlluminaHtp::InitialStockTubePurpose
    end

    factory(:mixed_submission_mx, class: Tube::MixedSubmissionMx) do
      target_type { 'StockMultiplexedLibraryTube' }
    end
  end

  factory :strip_tube_purpose, class: PlatePurpose do
    prefix { 'LS' }
    name               { generate :purpose_name }
    size               { '8' }
    asset_shape        { AssetShape.find_by!(name: 'StripTubeColumn') }
    target_type { 'StripTube' }
  end

  factory :plate_purpose do
    prefix { 'DN' }
    name { generate :purpose_name }
    size { 96 }
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
    target_type { 'Plate' }
    asset_shape { AssetShape.default }

    factory :source_plate_purpose do
      after(:build) do |source_plate_purpose, _evaluator|
        source_plate_purpose.source_purpose = source_plate_purpose
      end

      factory :input_plate_purpose, class: PlatePurpose::Input do
        stock_plate { true }
      end
    end

    factory :stock_plate_purpose do
      stock_plate { true }
    end
  end

  factory :dilution_plate_purpose do
    prefix { 'DN' }
    name { 'Dilution' }
  end

  factory :tube_purpose, class: Tube::Purpose do
    prefix { 'NT' }
    name        { generate :purpose_name }
    target_type { 'MultiplexedLibraryTube' }

    factory :sample_tube_purpose do
      target_type { 'SampleTube' }
    end

    factory :library_tube_purpose do
      target_type { 'SampleTube' }
    end

    factory :mx_tube_purpose do
      target_type { 'MultiplexedLibraryTube' }
    end

    factory :saphyr_tube_purpose do
      name { 'saphyr' }
      target_type { 'SampleTube' }
    end

  end

  factory :illumina_htp_mx_tube_purpose, class: IlluminaHtp::MxTubePurpose do
    prefix { 'NT' }
    sequence(:name) { |n| "Illumina HTP Mx Tube Purpose #{n}" }
    target_type { 'MultiplexedLibraryTube' }
  end

  factory(:parent_plate_purpose, class: PlatePurpose) do
    prefix { 'DN' }
    name { 'Parent plate purpose' }
  end

  # Plate creations
  factory(:pooling_plate_purpose, class: PlatePurpose) do
    prefix { 'DN' }
    sequence(:name) { |i| "Pooling purpose #{i}" }
    stock_plate { true }
  end

  factory(:initial_downstream_plate_purpose, class: Pulldown::InitialDownstreamPlatePurpose) do
    prefix { 'DN' }
    name { generate :pipeline_name }
  end

  # Tube creations
  factory(:child_tube_purpose, class: Tube::Purpose) do
    prefix { 'NT' }
    sequence(:name) { |n| "Child tube purpose #{n}" }
    target_type { 'Tube' }
  end
end
