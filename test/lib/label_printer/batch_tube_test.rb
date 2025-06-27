# frozen_string_literal: true

require 'test_helper'

class BatchTubeTest < ActiveSupport::TestCase
  attr_reader :tube_label, :batch

  context 'stock' do
    should 'return the right tubes and top line' do
      library_tube_with_stock_tube = create(:library_tube)
      stock_library_tube = create(:stock_library_tube)
      stock_library_tube.children << library_tube_with_stock_tube

      request = create(:sequencing_request, asset: library_tube_with_stock_tube)
      @batch = create(:batch)
      @batch.requests << request

      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: true }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal request.asset.labware.stock_asset.name, tube_label.first_line(tube)
    end
  end

  context 'no stock' do
    should 'return the right tubes and top line' do
      request = create(:sequencing_request, asset: create(:library_tube, barcode: '111'))
      @batch = create(:batch)
      @batch.requests << request

      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: false }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal request.asset.labware.name_for_label, tube_label.first_line(tube)
    end
  end
end
