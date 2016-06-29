require 'test_helper'

class BasePlateTest < ActiveSupport::TestCase

	attr_reader :base_plate_label, :plates, :plate1, :plate2, :label, :labels

	def setup
		@plates = create_list :plate, 2
		@plate1 = plates.first
		@plate2 = plates.last
		@label = {top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
						bottom_left: "#{plate1.sanger_human_barcode}",
						top_right: nil,
						bottom_right: nil,
						top_far_right: nil,
						barcode: "#{plate1.ean13_barcode}"}
		@labels = [{main_label:
									{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
									bottom_left: "#{plate1.sanger_human_barcode}",
									top_right: nil,
									bottom_right: nil,
									top_far_right: nil,
									barcode: "#{plate1.ean13_barcode}"}
								},
								{main_label:
									{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
									bottom_left: "#{plate2.sanger_human_barcode}",
									top_right: nil,
									bottom_right: nil,
									top_far_right: nil,
									barcode: "#{plate2.ean13_barcode}"}
								}
							]

		@base_plate_label = LabelPrinter::Label::BasePlate.new
	end

	test "should return the right label" do
		assert_equal label, base_plate_label.create_label(plate1)
		assert_equal ({main_label: label}), base_plate_label.label(plate1)
	end

	test "should return the right labels if count changes" do
		base_plate_label.plates = [plate1]
		base_plate_label.count = 3
		labels = [{main_label: label}, {main_label: label}, {main_label: label}]
		assert_equal labels, base_plate_label.labels
	end

	test "should return the right labels" do
		base_plate_label.plates = plates
		assert_equal labels, base_plate_label.labels
		assert_equal ({labels: {body: labels}}), base_plate_label.to_h
	end

	test "should return the right values for labels" do
		assert_equal plate1.sanger_human_barcode, base_plate_label.bottom_left(plate1)
		assert_equal plate1.ean13_barcode, base_plate_label.barcode(plate1)
		assert_equal Date.today.strftime("%e-%^b-%Y"), base_plate_label.top_left
	end


end