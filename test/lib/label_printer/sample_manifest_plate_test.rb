require 'test_helper'

class SampleManifestPlateTest < ActiveSupport::TestCase

	attr_reader :only_first_label, :manifest, :sample_manifest_label, :plate1, :plate2, :plates

	context "labels for plate sample manifest rapid_core" do

		setup do
			barcode = mock("barcode")
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      @manifest = create :sample_manifest, count: 2, rapid_generation: true
      @manifest.generate

			@plates = @manifest.core_behaviour.plates
			@plate1 = plates.first
			@plate2 = plates.last
			options = {sample_manifest: manifest, only_first_label: false}
			@sample_manifest_label = LabelPrinter::Label::SampleManifestPlate.new(options)
		end

		should "have the right plates" do
			assert_equal 2, sample_manifest_label.plates.count
			assert_equal plates, sample_manifest_label.plates
		end

		should "have the right plates if only first label required" do
			options = {sample_manifest: manifest, only_first_label: true}
			@sample_manifest_label = LabelPrinter::Label::SampleManifestPlate.new(options)
			assert_equal 1, sample_manifest_label.plates.count
			assert_equal [plate1], sample_manifest_label.plates
		end

		should "have the right values" do
			assert_equal PlatePurpose.stock_plate_purpose.name.to_s, sample_manifest_label.top_right(plate1)
			assert_equal "#{manifest.study.abbreviation} #{plate1.barcode}", sample_manifest_label.bottom_right(plate1)
		end

	end

	context "labels for plate sample manifest rapid_core" do

		setup do
			barcode = mock("barcode")
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      @manifest = create :sample_manifest, count: 2
      @manifest.generate

			@plates = @manifest.core_behaviour.samples.map { |s| s.primary_receptacle.plate }.uniq
			options = {sample_manifest: manifest, only_first_label: false}
			@sample_manifest_label = LabelPrinter::Label::SampleManifestPlate.new(options)
		end

		should "have the right plates" do
			assert_equal 2, plates.count
			assert_equal plates, sample_manifest_label.plates
		end

	end

end