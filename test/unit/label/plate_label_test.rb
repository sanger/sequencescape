require 'test_helper'

class PlateLabelTest < ActiveSupport::TestCase

	attr_reader :plate_label, :plate, :plate_purpose

	def setup
		plates = [].push create :child_plate
		@plate = plates[0]
		@plate_purpose = plate.plate_purpose
		options = {plate_purpose: plate_purpose, plates: plates, user_login: 'user'}
		@plate_label = Label::PlateLabel.new(options)
	end

	test 'should have plates' do
		assert plate_label.plates
	end

	test 'should return the correct hash' do
		labels = {body:
							[{main_label:
								{top_left: "#{Date.today}",
								bottom_left: "#{plate.sanger_human_barcode}",
								top_right: "#{plate_purpose.name.to_s}",
								bottom_right: "user #{plate.find_study_abbreviation_from_parent}",
								top_far_right: "#{plate.parent.try(:barcode)}",
								barcode: "#{plate.barcode}"}}]}
		assert_equal labels, plate_label.labels
		assert_equal ({labels: labels}), plate_label.to_h
	end

end