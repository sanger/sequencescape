require 'test_helper'

class SampleManifestMultiplexTest < ActiveSupport::TestCase

	attr_reader :only_first_label, :manifest, :sample_manifest_label, :mx_tube

	def setup

		@manifest = create :sample_manifest, asset_type: 'multiplexed_library', count: 3
		@manifest.generate

		@mx_tube = manifest.core_behaviour.mx_tube

		options = {sample_manifest: @manifest, only_first_label: false}
		@sample_manifest_label = LabelPrinter::Label::SampleManifestMultiplex.new(options)

	end

	test "should return correct tubes" do
		assert_equal [mx_tube], sample_manifest_label.tubes
	end

	test "should return correct top line" do
		assert_equal manifest.study.abbreviation, sample_manifest_label.top_line
	end

end