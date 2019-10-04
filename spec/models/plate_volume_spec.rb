# frozen_string_literal: true

require 'rails_helper'

describe PlateVolume do
  let(:plate_with_barcodes_in_csv) do
    # This plate has a CSV file in which the barcode is listed in the column
    create :plate,
           barcode: '1234567',
           well_count: 24,
           well_factory: :untagged_well,
           well_order: :row_order
  end
  let(:plate_without_barcodes_in_csv) do
    # This plate barcode is only used to name the volume check file
    create :plate,
           barcode: '111',
           well_count: 24,
           well_factory: :untagged_well,
           well_order: :row_order
  end

  describe '::process_all_volume_check_files' do
    let(:plate_a_expected_volumes) do
      {
        'A1' => 55.3281,
        'A2' => 25.296,
        'A3' => 0.1074,
        'A4' => 0.0547,
        'A5' => 0.0,
        'A6' => 0.0,
        'A7' => 0.0,
        'A8' => 0.0,
        'A9' => 0.0,
        'A10' => 0.0,
        'A11' => 0.0722,
        'A12' => 0.0794,
        'B1' => 53.0664,
        'B2' => 51.5682,
        'B3' => 0.0746,
        'B4' => 0.0064,
        'B5' => 0.0,
        'B6' => 0.0,
        'B7' => 0.0,
        'B8' => 0.0,
        'B9' => 0.0,
        'B10' => 0.0,
        'B11' => 0.0064,
        'B12' => 0.0547
      }
    end
    let(:plate_b_expected_volumes) do
      {
        'A1' => 0.0, 'A2' => 5.2463, 'A3' => 36.2634, 'A4' => 0.0, 'A5' => 0.0, 'A6' => 0.0, 'A7' => 11.057, 'A8' => 0.0, 'A9' => 0.0389, 'A10' => 0.0, 'A11' => 0.2391, 'A12' => 2.4558,
        'B1' => 8.5794, 'B2' => 0.0, 'B3' => 0.0, 'B4' => 0.0, 'B5' => 29.2206, 'B6' => 0.0, 'B7' => 0.0, 'B8' => 0.0, 'B9' => 0.0, 'B10' => 0.0, 'B11' => 3.4629, 'B12' => 4.4145
      }
    end

    setup do
      plate_with_barcodes_in_csv
      plate_without_barcodes_in_csv
      described_class.process_all_volume_check_files(Rails.root.join('test', 'data', 'plate_volume'))
    end
    # We don't use two separate contexts as we want to make sure we handle all plates
    # in each update
    it 'updates measured and current volumes' do
      wells = plate_with_barcodes_in_csv.wells.includes(:well_attribute, :map).index_by(&:map_description)
      plate_a_expected_volumes.each do |well_name, volume|
        well_attribute = wells[well_name].well_attribute
        expect(well_attribute.measured_volume).to eq volume
        expect(well_attribute.current_volume).to eq volume
      end
    end

    it 'updates measured and current volumes for plate_without_barcodes_in_csv' do
      wells = plate_without_barcodes_in_csv.wells.includes(:well_attribute, :map).index_by(&:map_description)
      plate_b_expected_volumes.each do |well_name, volume|
        well_attribute = wells[well_name].well_attribute
        expect(well_attribute.measured_volume).to eq volume
        expect(well_attribute.current_volume).to eq volume
      end
    end

    it 'generates a QcResult for each well' do
      plate_with_barcodes_in_csv.wells.includes(:well_attribute, :map).each do |well|
        expect(well.qc_results).to be_one
        expect(well.qc_results.first.key).to eq('volume')
        expect(well.qc_results.first.assay_type).to eq('Volume Check')
      end
    end
  end
end
