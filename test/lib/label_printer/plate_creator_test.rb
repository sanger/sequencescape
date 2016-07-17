require 'test_helper'

class PlateCreatorTest < ActiveSupport::TestCase

	attr_reader :plate_label, :plate, :plate_purpose, :label

	def setup
		plates = [(create :child_plate)]
		@plate = plates.first
		@plate_purpose = plate.plate_purpose
		options = {plate_purpose: plate_purpose, plates: plates, user_login: 'user'}
		@plate_label = LabelPrinter::Label::PlateCreator.new(options)
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
		assert_equal label, plate_label.label(plate)
	end

	test 'should return the correct hash' do
		labels = 	{body: [label]}
		assert_equal labels, plate_label.labels
	end

end