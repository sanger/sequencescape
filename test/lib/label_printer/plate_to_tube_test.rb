# frozen_string_literal: true

require 'test_helper'
require_relative 'shared_tests'

class PlateToTubesTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :tube_label, :sample_tubes, :prefix, :barcode1, :tube1, :label, :asset_name

  def setup # rubocop:todo Metrics/AbcSize
    @prefix = 'NT'
    @barcode1 = '1111'
    @asset_name = 'tube name'
    @tube1 = create(:sample_tube, :tube_barcode, barcode: barcode1, prefix: prefix, name: asset_name)
    @sample_tubes = create_list(:sample_tube, 4, :tube_barcode)
    sample_tubes.unshift(tube1)
    options = { sample_tubes: }
    @tube_label = LabelPrinter::Label::PlateToTubes.new(options)
    @label = {
      first_line: asset_name.to_s,
      second_line: barcode1,
      third_line: Date.today.strftime('%e-%^b-%Y').to_s,
      round_label_top_line: prefix,
      round_label_bottom_line: barcode1,
      barcode: tube1.machine_barcode,
      label_name: 'main_label'
    }
  end

  test 'should have tubes' do
    assert_equal 5, tube_label.tubes.count
  end

  test 'should return correct top line' do
    assert_equal asset_name, tube_label.first_line(sample_tubes.first)
  end
end
