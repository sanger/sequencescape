require 'test_helper'

class SampleManifestLabelTest < ActiveSupport::TestCase

	attr_reader :only_first_label, :manifest, :sample_manifest_label, :plate1, :plate2

	context "labels for plate sample manifest" do

		setup do
			barcode = mock("barcode")
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      @manifest = create :sample_manifest, count: 2, rapid_generation: true
      @manifest.generate
      SampleManifestTemplate.first.generate(@manifest)
			plates = @manifest.core_behaviour.plates
			@plate1 = plates.first
			@plate2 = plates.last
			only_first_label = false
			options = {sample_manifest: manifest, only_first_label: only_first_label}
			@sample_manifest_label = LabelPrinter::Label::SampleManifestLabel.new(options)
		end

		should "have sample_manifest" do
			assert sample_manifest_label.sample_manifest
		end

		should "return the correct hash" do
			labels = 	[{main_label:
										{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
										bottom_left: "#{plate1.sanger_human_barcode}",
										top_right: "#{PlatePurpose.stock_plate_purpose.name.to_s}",
										bottom_right: "#{manifest.study.abbreviation} #{plate1.barcode}",
										barcode: "#{plate1.ean13_barcode}"}
									},
									{main_label:
										{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
										bottom_left: "#{plate2.sanger_human_barcode}",
										top_right: "#{PlatePurpose.stock_plate_purpose.name.to_s}",
										bottom_right: "#{manifest.study.abbreviation} #{plate2.barcode}",
										barcode: "#{plate2.ean13_barcode}"}
									}
								]
			assert_equal labels, sample_manifest_label.labels
			assert_equal ({labels: {body: labels}}), sample_manifest_label.to_h
		end

	end

end