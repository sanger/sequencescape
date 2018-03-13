# frozen_string_literal: true

FactoryGirl.define do
  factory :purpose do
    name { generate :purpose_name }
    target_type 'Asset'

    factory :stock_purpose do
      stock_plate true
    end

    factory(:new_stock_tube_purpose, class: IlluminaHtp::StockTubePurpose) do
      target_type 'StockMultiplexedLibraryTube'

      factory :illumina_htp_initial_stock_tube_purpose, class: IlluminaHtp::InitialStockTubePurpose
    end

    factory(:mixed_submission_mx, class: Tube::MixedSubmissionMx) do
      target_type 'StockMultiplexedLibraryTube'
    end
  end

  factory :strip_tube_purpose, class: PlatePurpose do
    name               { generate :purpose_name }
    size               '8'
    asset_shape        { AssetShape.find_by!(name: 'StripTubeColumn') }
    barcode_for_tecan  'ean13_barcode'
    target_type 'StripTube'
  end

  factory :plate_purpose do
    name { generate :purpose_name }
    size 96
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
    target_type 'Plate'
    asset_shape { AssetShape.default }

    factory :source_plate_purpose do
      after(:build) do |source_plate_purpose, _evaluator|
        source_plate_purpose.source_purpose = source_plate_purpose
      end

      factory :input_plate_purpose, class: PlatePurpose::Input do
        stock_plate true
      end
    end
  end

  factory :dilution_plate_purpose do
    name 'Dilution'
  end

  factory :tube_purpose, class: Tube::Purpose do
    name        { generate :purpose_name }
    target_type 'MultiplexedLibraryTube'
  end
end
