require 'test_helper'

class SampleManifestPlateTest < ActiveSupport::TestCase
  attr_reader :only_first_label, :manifest, :plate_label, :plate1, :plate2, :plates, :study_abbreviation, :purpose, :barcode1, :label

  context 'labels for plate sample manifest rapid_core' do
    setup do
      barcode = mock('barcode')
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      @purpose = create :plate_purpose

      @manifest = create :sample_manifest, count: 2, rapid_generation: true, purpose: @purpose
      @manifest.generate

      @plates = @manifest.send(:core_behaviour).plates
      @plate1 = plates.first
      @plate2 = plates.last
      @study_abbreviation = 'WTCCC'
      @barcode1 = plate1.barcode.to_s

      options = { sample_manifest: manifest, only_first_label: false, purpose: @purpose }
      @plate_label = LabelPrinter::Label::SampleManifestPlate.new(options)
      @label = { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
                 bottom_left: (plate1.sanger_human_barcode).to_s,
                 top_right: purpose.name,
                 bottom_right: "#{study_abbreviation} #{barcode1}",
                 top_far_right: nil,
                 barcode: (plate1.ean13_barcode).to_s }
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
      assert_equal label, plate_label.create_label(plate1)
      assert_equal ({ main_label: label }), plate_label.label(plate1)
    end
  end
end
