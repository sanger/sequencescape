require 'test_helper'

class SequenomPlateTest < ActiveSupport::TestCase

	attr_reader :sequenom_label, :label, :plate

	def setup
		@plate = create :sequenom_qc_plate, barcode: "7777", name: 'QC134443_9168137_163993_160200_20160617'
		options = {plates: [plate], count: 1}
		@sequenom_label = LabelPrinter::Label::SequenomPlate.new(options)
		@label =	{main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{plate.sanger_human_barcode}",
								top_right: "#{plate.label_text_top}",
								bottom_right: "#{plate.label_text_bottom}",
								top_far_right: "#{plate.plate_purpose.name}",
								barcode: "#{plate.ean13_barcode}"}
							}
	end

	test 'should have plates' do
		assert sequenom_label.plates
	end

	test 'should return the right label for a plate' do
		assert_equal label, sequenom_label.create_label(plate)
	end

	test 'should return the correct hash' do
		labels = 	[label]
		assert_equal labels, sequenom_label.labels
		assert_equal ({labels: {body: labels}}), sequenom_label.to_h
	end

	test 'should return the correct hash if several copies are required' do
		options = {plates: [plate], count: '3'}
		@sequenom_label = LabelPrinter::Label::SequenomPlate.new(options)
		labels = [label, label, label]
		assert_equal labels, sequenom_label.labels
		assert_equal ({labels: {body: labels}}), sequenom_label.to_h
	end


end