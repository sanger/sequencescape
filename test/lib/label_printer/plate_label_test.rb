require 'test_helper'

class PlateLabelTest < ActiveSupport::TestCase

	attr_reader :plate_label, :plate, :plate_purpose, :label

	def setup
		plates = [(create :child_plate)]
		@plate = plates.first
		@plate_purpose = plate.plate_purpose
		options = {plate_purpose: plate_purpose, plates: plates, user_login: 'user'}
		@plate_label = LabelPrinter::Label::PlateLabel.new(options)
		@label =	{main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{plate.sanger_human_barcode}",
								top_right: "#{plate_purpose.name.to_s}",
								bottom_right: "#{plate_label.user_login} #{plate.find_study_abbreviation_from_parent}",
								top_far_right: "#{plate.parent.try(:barcode)}",
								barcode: "#{plate.ean13_barcode}"}
							}
	end

	test 'should have plates' do
		assert plate_label.plates
	end

	test 'should return the right label for a plate' do
		assert_equal label, plate_label.create_label(plate)
	end

	test 'should return the correct hash' do
		labels = 	[label]
		assert_equal labels, plate_label.labels
		assert_equal ({labels: {body: labels}}), plate_label.to_h
	end

end