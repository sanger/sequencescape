# frozen_string_literal: true

require 'test_helper'

class SampleManifestPlateTest < ActiveSupport::TestCase
  attr_reader :only_first_label,
              :manifest,
              :plate_label,
              :plate1,
              :plate2,
              :plates,
              :study_abbreviation,
              :purpose,
              :barcode1,
              :label

  context 'labels for plate sample manifest rapid_core' do
    setup do
      PlateBarcode.stubs(:create_barcode).returns(
        build(:plate_barcode, barcode: 'SQPD-23'),
        build(:plate_barcode, barcode: 'SQPD-24')
      )

      @purpose = create(:plate_purpose)

      @manifest = create(:sample_manifest, count: 2, purpose: @purpose)
      @manifest.generate

      @plates = @manifest.send(:core_behaviour).plates
      @plate1 = plates.first
      @plate2 = plates.last
      @study_abbreviation = 'WTCCC'
      @barcode1 = plate1.barcode_number.to_s

      options = { sample_manifest: manifest, only_first_label: false, purpose: @purpose }
      @plate_label = LabelPrinter::Label::SampleManifestPlate.new(options)
      @label = {
        top_left: Date.today.strftime('%e-%^b-%Y').to_s,
        bottom_left: plate1.human_barcode.to_s,
        top_right: purpose.name,
        bottom_right: "#{study_abbreviation} #{barcode1}",
        top_far_right: nil,
        barcode: plate1.machine_barcode.to_s,
        label_name: 'main_label'
      }
    end

    should 'have the right plates' do
      assert_equal 2, plate_label.plates.count
      assert_equal plates, plate_label.assets
    end

    should 'have the right plates if only first label required' do
      options = { sample_manifest: manifest, only_first_label: true }
      @plate_label = LabelPrinter::Label::SampleManifestPlate.new(options)

      assert_equal 1, plate_label.plates.count
      assert_equal [plate1], plate_label.plates
    end

    should 'have the correct specific values' do
      assert_equal purpose.name, plate_label.top_right(plate1)
      assert_equal "#{study_abbreviation} #{barcode1}", plate_label.bottom_right(plate1)
    end

    should 'should return correct common values' do
      assert_match barcode1, plate_label.bottom_left(plate1)
      assert_match barcode1, plate_label.barcode(plate1)
    end

    should 'should return the correct label' do
      assert_equal label, plate_label.build_label(plate1)
    end
  end

  # Testing of core manifests removed in:
  # e765a07bb3034d615573371ff3b5001003828e63
  # - At time of writing core is only used by the API which does not use this
  #   label template.
  # - Manifest generation is slow, and the test takes 30s to run.
  # - This resulted in an expensive test for an unused code path.
end
