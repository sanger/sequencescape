require 'test_helper'

class AssetPlateTest < ActiveSupport::TestCase

	attr_reader :asset_label, :label, :plate

	def setup
		asset = create :child_plate
		options = {asset: asset}
		@asset_label = LabelPrinter::Label::AssetPlate.new(options)
		@plate = asset
		@label =	{main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{plate.sanger_human_barcode}",
								top_right: "#{plate.prefix} #{plate.barcode}",
								bottom_right: "#{plate.name_for_label.to_s} #{plate.barcode}",
								top_far_right: nil,
								barcode: "#{plate.ean13_barcode}"}
							}
	end

	test 'should have plates' do
		assert asset_label.plates
	end

	test 'should return the right label for a plate' do
		assert_equal label, asset_label.create_label(plate)
	end

	test 'should return the correct hash' do
		labels = 	[label]
		assert_equal labels, asset_label.labels
		assert_equal ({labels: {body: labels}}), asset_label.to_h
	end


end