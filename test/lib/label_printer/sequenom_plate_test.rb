require 'test_helper'

class SequenomPlateTest < ActiveSupport::TestCase

	attr_reader :sequenom_label, :label, :plate

	def setup
		@plate = create :sequenom_qc_plate, barcode: "7777", name: 'QC134443_9168137_163993_160200_20160617'
		options = {plates: [plate], count: 1}
		@sequenom_label = LabelPrinter::Label::SequenomPlate.new(options)
	end

	test 'should have plates' do
		assert sequenom_label.plates
	end

	test 'should return the right values' do
		assert_equal "#{plate.label_text_top}", sequenom_label.top_right(plate)
		assert_equal "#{plate.label_text_bottom}", sequenom_label.bottom_right(plate)
		assert_equal "#{plate.plate_purpose.name}", sequenom_label.top_far_right(plate)
	end


end