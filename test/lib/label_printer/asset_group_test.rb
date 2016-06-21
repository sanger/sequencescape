require 'test_helper'

class AssetGroupTest < ActiveSupport::TestCase

	attr_reader :asset_group_label, :labels, :plates, :asset1, :asset2

	def setup
		@asset1 = create :child_plate
		@asset2 = create :child_plate
		asset3 = create :child_plate
		options = {printables: {"#{asset1.id}"=>"true", "#{asset2.id}" => "true", "#{asset3.id}" => "false"}}
		@asset_group_label = LabelPrinter::Label::AssetGroup.new(options)
		@plates = [asset1, asset2]
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

	test 'should have printables' do
		assert asset_group_label.printables
	end

	test 'should return the right plates' do
		assert_equal plates, asset_group_label.plates
	end

	test 'should return the correct hash' do
		assert_equal labels, asset_group_label.labels
		assert_equal ({labels: {body: labels}}), asset_group_label.to_h
	end


end