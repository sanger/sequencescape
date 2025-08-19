# frozen_string_literal: true

FactoryBot.define do
  factory :purpose do
    prefix { 'DN' }
    name { generate(:purpose_name) }
    target_type { 'Asset' }

    factory :stock_purpose do
      stock_plate { true }
    end

    factory(:new_stock_tube_purpose, class: 'IlluminaHtp::StockTubePurpose') do
      target_type { 'StockMultiplexedLibraryTube' }

      factory :illumina_htp_initial_stock_tube_purpose, class: 'IlluminaHtp::InitialStockTubePurpose'
    end
  end

  factory :strip_tube_purpose, class: 'PlatePurpose' do
    prefix { 'LS' }
    name { generate(:purpose_name) }
    size { '8' }
    asset_shape { create(:strip_tube_column_shape) }
    target_type { 'StripTube' }
  end

  factory :plate_purpose do
    prefix { 'DN' }
    name { generate(:purpose_name) }
    size { 96 }
    barcode_printer_type factory: %i[plate_barcode_printer_type]
    target_type { 'Plate' }
    asset_shape { AssetShape.default }

    factory :source_plate_purpose do
      after(:build) { |source_plate_purpose, _evaluator| source_plate_purpose.source_purpose = source_plate_purpose }

      factory :input_plate_purpose, class: 'PlatePurpose::Input' do
        stock_plate { true }
      end
    end

    factory :stock_plate_purpose do
      stock_plate { true }
    end

    factory :pico_assay_purpose do
      target_type { 'PicoAssayPlate' }
    end

    factory :fluidigm_96_purpose do
      cherrypick_direction { 'interlaced_column' }
      size { 96 }
      asset_shape factory: %i[fluidigm_96_shape]
    end
    factory :fluidigm_192_purpose do
      cherrypick_direction { 'interlaced_column' }
      size { 192 }
      asset_shape factory: %i[fluidigm_192_shape]
    end

    factory :shape4x1_purpose do
      size { 16 }
      asset_shape { AssetShape.find_by(name: 'Shape4x1') }
    end

    factory :shape8x1_purpose do
      size { 8 }
      asset_shape { AssetShape.find_by(name: 'Shape8x1') }
    end
  end

  factory :dilution_plate_purpose do
    prefix { 'DN' }
    name { 'Dilution' }
  end

  factory :working_dilution_plate_purpose, class: 'DilutionPlatePurpose' do
    name { generate(:purpose_name) }
    target_type { 'WorkingDilutionPlate' }
    prefix { 'WD' }
  end

  factory :tube_purpose, class: 'Tube::Purpose' do
    prefix { 'NT' }
    name { generate(:purpose_name) }
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

    factory :long_read_tube_purpose do
      name { 'long_read' }
      target_type { 'SampleTube' }
    end
  end

  factory :std_mx_tube_purpose, class: 'Tube::StandardMx' do
    prefix { 'NT' }
    name { generate(:purpose_name) }
    target_type { 'MultiplexedLibraryTube' }
  end

  factory :illumina_htp_mx_tube_purpose, class: 'IlluminaHtp::MxTubePurpose' do
    prefix { 'NT' }
    sequence(:name) { |n| "Illumina HTP Mx Tube Purpose #{n}" }
    target_type { 'MultiplexedLibraryTube' }
  end

  factory(:parent_plate_purpose, class: 'PlatePurpose') do
    prefix { 'DN' }
    name { 'Parent plate purpose' }
  end

  # Plate creations
  factory(:pooling_plate_purpose, class: 'PlatePurpose') do
    prefix { 'DN' }
    sequence(:name) { |i| "Pooling purpose #{i}" }
    stock_plate { true }
  end

  # Tube creations
  factory(:child_tube_purpose, class: 'Tube::Purpose') do
    prefix { 'NT' }
    sequence(:name) { |n| "Child tube purpose #{n}" }
    target_type { 'Tube' }
  end

  factory :tube_rack_purpose, class: 'TubeRack::Purpose' do
    target_type { 'TubeRack' }
    name { generate(:purpose_name) }
    size { 96 }

    factory :tube_rack_purpose_48 do
      size { 48 }
    end
  end
end
