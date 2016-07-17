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

end