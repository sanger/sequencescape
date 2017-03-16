require 'test_helper'

class BatchTubeTest < ActiveSupport::TestCase
  attr_reader :tube_label, :batch

  context 'stock' do
    should 'when multiplexed should return the right tubes and top line' do
      pipeline = create :pipeline,
        name: 'Test pipeline',
        workflow: LabInterface::Workflow.create!(item_limit: 8),
        multiplexed: true
      batch = pipeline.batches.create!

      library_tube_with_stock_tube = create :library_tube, barcode: '111'
      stock_library_tube = create :stock_library_tube
      stock_library_tube.children << library_tube_with_stock_tube
      child = create :library_tube
      library_tube_with_stock_tube.children << child

      request = create :multiplexed_library_creation_request, target_asset: library_tube_with_stock_tube
      batch.requests << request
      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: true }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal child.name, tube_label.top_line(tube)
    end

    should 'when not multiplexed should return the right tubes and top line' do
      library_tube_with_stock_tube = create :library_tube
      stock_library_tube = create :stock_library_tube
      stock_library_tube.children << library_tube_with_stock_tube

      request = create :library_creation_request, target_asset: library_tube_with_stock_tube
      @batch = create :batch
      @batch.requests << request

      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: true }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal request.target_asset.stock_asset.name, tube_label.top_line(tube)
    end
  end

  context 'no stock' do
    should 'when multiplexed should return the right tubes and top line' do
      @pipeline = create :pipeline,
        name: 'Test pipeline',
        workflow: LabInterface::Workflow.create!(item_limit: 8),
        multiplexed: true

      batch = @pipeline.batches.create!
      tag_map_id = 3
      library_tube = create :tagged_library_tube, barcode: '111', tag_map_id: tag_map_id
      request = create :multiplexed_library_creation_request, target_asset: library_tube
      batch.requests << request

      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: false }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal "(#{tag_map_id}) #{request.target_asset.id}", tube_label.top_line(tube)
    end

    should 'when not multiplexed should return the right tubes and top line' do
      request = create :library_creation_request, target_asset: (create :library_tube, barcode: '111')
      @batch = create :batch
      @batch.requests << request

      printable = { request.id => 'on' }
      options = { count: '1', printable: printable, batch: batch, stock: false }
      @tube_label = LabelPrinter::Label::BatchTube.new(options)

      assert_equal 1, tube_label.tubes.count
      tube = tube_label.tubes.first
      assert_equal request.target_asset.tube_name, tube_label.top_line(tube)
    end
  end
end
