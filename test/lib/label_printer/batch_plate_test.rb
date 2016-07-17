require 'test_helper'

class BatchPlateTest < ActiveSupport::TestCase

	attr_reader :batch_plate_label, :label, :plate, :batch, :printable

	def setup
		study = create :study
    project = create :project
    asset = create :empty_sample_tube
    order_role = Order::OrderRole.new role: 'test'

		order = create :order, order_role: order_role, study: study, assets: [asset], project: project
 		request = create :well_request, asset: (create :well_with_sample_and_plate), target_asset: (create :well_with_sample_and_plate), order: order

 		@batch = create :batch
 		batch.requests << request

 		@plate = batch.plate_group_barcodes.keys[0]

 		@printable = {@plate.barcode => "on"}

		options = {count: '3', printable: printable, batch: batch}

		@batch_plate_label = LabelPrinter::Label::BatchPlate.new(options)

	end

	test 'should have count' do
		assert_equal 3, batch_plate_label.count
	end

	test 'should have return the right plates' do
		assert_equal [plate], batch_plate_label.plates
	end

	test 'should return the right values' do
		assert_equal batch.study.abbreviation, batch_plate_label.top_right(plate)
		assert_equal "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate.barcode}", batch_plate_label.bottom_right(plate)
	end

end