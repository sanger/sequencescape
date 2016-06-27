require 'test_helper'

class SampleManifestTubeTest < ActiveSupport::TestCase

	attr_reader :manifest, :sample_manifest_label, :tube1, :tube2, :tube3

	def setup

		@manifest = create :sample_manifest, asset_type: '1dtube', count: 3
		@manifest.generate

		@tube1 = manifest.samples.first.assets.first
		@tube2 = manifest.samples[1].assets.first
		@tube3 = manifest.samples[2].assets.first

		options = {sample_manifest: @manifest, only_first_label: false}
		@sample_manifest_label = LabelPrinter::Label::SampleManifestTube.new(options)

	end

	test "should return the right list of tubes" do
		assert_equal 3, sample_manifest_label.tubes.count
		assert_equal manifest.samples.first.assets.first, sample_manifest_label.tubes.first
	end

	test "returns only one tube if required to do so" do
		options = {sample_manifest: manifest, only_first_label: true}
		@sample_manifest_label = LabelPrinter::Label::SampleManifestTube.new(options)

		assert_equal 1, sample_manifest_label.tubes.count
		assert_equal manifest.samples.first.assets.first, sample_manifest_label.tubes.first
	end

	test "should return a correct label" do
		label = {top_line: manifest.study.abbreviation,
					middle_line: tube1.barcode,
					bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
					round_label_top_line: tube1.prefix,
					round_label_bottom_line: tube1.barcode,
					barcode: tube1.ean13_barcode}
		assert_equal label, sample_manifest_label.label(tube1)
	end

	test "should return correct labels" do
		labels = 	[{main_label:
								{top_line: manifest.study.abbreviation,
									middle_line: tube1.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: tube1.prefix,
									round_label_bottom_line: tube1.barcode,
									barcode: tube1.ean13_barcode}},
							{main_label:
								{top_line: manifest.study.abbreviation,
									middle_line: tube2.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: tube2.prefix,
									round_label_bottom_line: tube2.barcode,
									barcode: tube2.ean13_barcode}},
							{main_label:
								{top_line: manifest.study.abbreviation,
									middle_line: tube3.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: tube3.prefix,
									round_label_bottom_line: tube3.barcode,
									barcode: tube3.ean13_barcode}}]
		assert_equal labels, sample_manifest_label.labels
		assert_equal ({labels: {body: labels}}), sample_manifest_label.to_h
	end
end