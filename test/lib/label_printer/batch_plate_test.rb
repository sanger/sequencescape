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

 		@plate = batch.output_plates[0]

 		@printable = {batch.output_plates[0].barcode => "on"}

		options = {count: '1', printable: printable, batch: batch}

		@batch_plate_label = LabelPrinter::Label::BatchPlate.new(options)

		@label = {main_label:
								{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
								bottom_left: "#{plate.sanger_human_barcode}",
								top_right: "#{batch.study.abbreviation}",
								bottom_right: "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate.barcode}",
								top_far_right: nil,
								barcode: "#{plate.ean13_barcode}"}
							}
	end

	test 'should have batch' do
		assert batch_plate_label.batch
	end

	test 'should return the right label for a plate' do
		assert_equal label, batch_plate_label.create_label(plate)
	end

	test 'should return the correct hash' do
		labels = 	[label]
		assert_equal labels, batch_plate_label.labels
		assert_equal ({labels: {body: labels}}), batch_plate_label.to_h
	end

	test 'should return the correct hash if several copies are required' do
		options = {count: '3', printable: printable, batch: batch}
		@batch_plate_label = LabelPrinter::Label::BatchPlate.new(options)
		labels = [label, label, label]
		assert_equal labels, batch_plate_label.labels
		assert_equal ({labels: {body: labels}}), batch_plate_label.to_h
	end

end