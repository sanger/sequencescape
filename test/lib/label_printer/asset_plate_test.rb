require 'test_helper'

class AssetPlateTest < ActiveSupport::TestCase

	attr_reader :asset_plate_label, :labels, :plates, :asset1, :asset2

	def setup
		@asset1 = create :child_plate
		@asset2 = create :child_plate
		@plates = [asset1, asset2]
		@asset_plate_label = LabelPrinter::Label::AssetPlate.new(plates)

	end

	test 'should return the right plates' do
		assert_equal plates, asset_plate_label.plates
	end

	test 'should return the correct values' do
		assert_equal "#{asset1.prefix} #{asset1.barcode}", asset_plate_label.top_right(asset1)
		assert_equal "#{asset1.name_for_label.to_s} #{asset1.barcode}", asset_plate_label.bottom_right(asset1)
	end


end