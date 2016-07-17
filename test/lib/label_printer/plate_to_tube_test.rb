require 'test_helper'

class PlateToTubesTest < ActiveSupport::TestCase

	attr_reader :plate_to_tubes_label, :sample_tubes

	def setup

		@sample_tubes = create_list :sample_tube, 5

		options = {sample_tubes: sample_tubes}
		@plate_to_tubes_label = LabelPrinter::Label::PlateToTubes.new(options)

	end

	test "should have tubes" do
		assert_equal 5, plate_to_tubes_label.tubes.count
	end

	test "should return correct top line" do
		assert_equal sample_tubes.first.tube_name, plate_to_tubes_label.top_line(sample_tubes.first)
	end

end