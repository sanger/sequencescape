# frozen_string_literal: true

require 'test_helper'
require 'csv'
class ImportFluidigmDataTest < ActiveSupport::TestCase
  XY = 'M'
  XX = 'F'
  YY = 'F'
  NC = 'Unknown'

  def create_fluidigm_file
    @file = File.open("#{Rails.root}/test/data/fluidigm.csv")
    @fluidigm = FluidigmFile.new(@file.read)
    @well_maps = {
      'S06' => {
        markers: [XY, XY, XY],
        count: 94
      },
      'S04' => {
        markers: [NC, XX, XX],
        count: 92
      },
      'S43' => {
        markers: [XX, XX, XX],
        count: 94
      }
    }
    @fluidigm
  end

  def create_stock_plate(barcode)
    create(
      :plate,
      name: "Stock plate #{barcode}",
      well_count: 1,
      well_factory: :untagged_well,
      purpose: PlatePurpose.stock_plate_purpose,
      barcode: barcode
    )
  end

  def create_plate_with_fluidigm(_barcode, fluidigm_barcode, stock_plate)
    fgp = create(:fluidigm_96_purpose)
    plate_target =
      create(
        :plate,
        size: 96,
        purpose: fgp,
        well_count: 1,
        well_factory: :empty_well,
        fluidigm_barcode: fluidigm_barcode
      )

    well_target = plate_target.wells.first

    create(
      :final_cherrypick_for_fluidigm_request,
      state: 'passed',
      asset: stock_plate.wells.first,
      target_asset: well_target,
      request_metadata_attributes: {
        target_purpose_id: fgp.id
      },
      request_type: @fluidigm_request_type
    )

    plate_target
  end

  context 'With a fluidigm file' do
    setup do
      @fluidigm_request_type = create(:request_type, key: 'pick_to_fluidigm')
      @fluidigm_file = create_fluidigm_file
      @stock_plate = create_stock_plate('SQPD-8765432')
      @plate1 = create_plate_with_fluidigm('1234567', '1381832088', @stock_plate)
      @plate2 = create_plate_with_fluidigm('1234568', '1234567891', @stock_plate)
    end

    context 'before uploading the fluidigm file to a corresponding plate' do
      should 'we get this plate inside the requiring_fluidigm_data scope' do
        @plates_requiring_fluidigm = Plate.requiring_fluidigm_data

        assert_includes @plates_requiring_fluidigm, @plate1
        assert_includes @plates_requiring_fluidigm, @plate2
      end
    end
    context 'after uploading the fluidigm file' do
      setup { @plate1.apply_fluidigm_data(@fluidigm_file) }

      should "we only get the plates that haven't been updated yet" do
        @plates_requiring_fluidigm = Plate.requiring_fluidigm_data

        assert_equal false, @plates_requiring_fluidigm.include?(@plate1)
        assert_equal true, @plates_requiring_fluidigm.include?(@plate2)
      end

      should 'update the plate fluidigm data' do
        well = @stock_plate.wells.located_at('A1').first

        assert_equal %w[M M M], well.get_gender_markers
        assert_equal 89, well.get_sequenom_count
        assert_equal 2, well.qc_results.count
        assert_includes well.qc_results.map(&:key), 'gender_markers'
        assert_includes well.qc_results.map(&:key), 'loci_passed'
      end
    end
  end
end
