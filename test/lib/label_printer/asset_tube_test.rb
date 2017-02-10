require 'test_helper'
require_relative 'shared_tests'

class AssetTubeTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :tube_label, :label, :tubes, :tube1, :tube2, :barcode1, :prefix, :asset_name

  def setup
    @barcode1 = '11111'
    @prefix = 'NT'
    @asset_name = 'tube name'
    @tube1 = create :sample_tube, barcode: barcode1, name: asset_name
    @tube2 = create :sample_tube
    @tubes = [tube1, tube2]
    @tube_label = LabelPrinter::Label::AssetTube.new(tubes)
    @label = { top_line: (asset_name).to_s,
               middle_line: barcode1,
               bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
               round_label_top_line: prefix,
               round_label_bottom_line: barcode1,
               barcode: tube1.ean13_barcode }
  end

  test 'should return the right tubes' do
    assert_equal tubes, tube_label.assets
  end

  test 'should return correct top_line value' do
    assert_equal (asset_name).to_s, tube_label.top_line(tube1)
  end
end
