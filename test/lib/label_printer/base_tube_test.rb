require 'test_helper'

class BaseTubeTest < ActiveSupport::TestCase

	attr_reader :base_tube_label, :tubes, :tube1, :tube2, :label, :labels

	def setup
		@tubes = create_list :sample_tube, 2
		@tube1 = tubes.first
		@tube2 = tubes.last
		@label = {top_line: nil,
							middle_line: tube1.barcode,
							bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
							round_label_top_line: tube1.prefix,
							round_label_bottom_line: tube1.barcode,
							barcode: tube1.ean13_barcode}
		@labels = {body: [{main_label:
								{top_line: nil,
									middle_line: tube1.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: tube1.prefix,
									round_label_bottom_line: tube1.barcode,
									barcode: tube1.ean13_barcode}},
							{main_label:
								{top_line: nil,
									middle_line: tube2.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: tube2.prefix,
									round_label_bottom_line: tube2.barcode,
									barcode: tube2.ean13_barcode}}]}

		@base_tube_label = LabelPrinter::Label::BaseTube.new
	end

	test "should return the right label" do
		assert_equal label, base_tube_label.create_label(tube1)
		assert_equal ({main_label: label}), base_tube_label.label(tube1)
	end

	test "should return the right labels if count changes" do
		base_tube_label.tubes = [tube1]
		base_tube_label.count = 3
		labels = {body: [{main_label: label}, {main_label: label}, {main_label: label}]}
		assert_equal labels, base_tube_label.labels
	end

	test "should return the right labels" do
		base_tube_label.tubes = tubes
		assert_equal labels, base_tube_label.labels
		assert_equal ({labels: labels}), base_tube_label.to_h
	end

	test "should return the right values for labels" do
		assert_equal tube1.prefix, base_tube_label.round_label_top_line(tube1)
		assert_equal tube1.barcode, base_tube_label.round_label_bottom_line(tube1)
	  assert_equal tube1.barcode, base_tube_label.middle_line(tube1)
		assert_equal Date.today.strftime("%e-%^b-%Y"), base_tube_label.bottom_line
		assert_equal tube1.ean13_barcode, base_tube_label.barcode(tube1)
	end


end