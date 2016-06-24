require 'test_helper'

class AssetPlateTest < ActiveSupport::TestCase

	attr_reader :asset_plate_label, :labels, :plates, :asset1, :asset2

	def setup
		@asset1 = create :child_plate
		@asset2 = create :child_plate
		@plates = [asset1, asset2]
		@asset_plate_label = LabelPrinter::Label::AssetPlate.new(plates)

		@labels =	[{main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{asset1.sanger_human_barcode}",
								top_right: "#{asset1.prefix} #{asset1.barcode}",
								bottom_right: "#{asset1.name_for_label.to_s} #{asset1.barcode}",
								top_far_right: nil,
								barcode: "#{asset1.ean13_barcode}"}
							},
							{main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{asset2.sanger_human_barcode}",
								top_right: "#{asset2.prefix} #{asset2.barcode}",
								bottom_right: "#{asset2.name_for_label.to_s} #{asset2.barcode}",
								top_far_right: nil,
								barcode: "#{asset2.ean13_barcode}"}
							}
						]
	end

	test 'should return the right plates' do
		assert_equal plates, asset_plate_label.plates
	end

	test 'should return the correct hash' do
		assert_equal labels, asset_plate_label.labels
		assert_equal ({labels: {body: labels}}), asset_plate_label.to_h
	end


end