require 'test_helper'
require_relative 'shared_tests'

class BatchMultiplexTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :tube_label, :prefix, :barcode1, :tube1, :label

  def setup
    pipeline = create :pipeline,
      name: 'Test pipeline',
      workflow: LabInterface::Workflow.create!(item_limit: 8),
      multiplexed: true
    batch = pipeline.batches.create!

    @prefix = 'NT'
    @barcode1 = '1111'
    @tube_name = 'tube name'
    @tube1 = create :library_tube, barcode: barcode1, name: @tube_name

    printable = { tube1.id => 'on' }
    options = { count: '1', printable: printable, batch: batch }
    @tube_label = LabelPrinter::Label::BatchMultiplex.new(options)
    @label = { top_line: "(p) #{@tube_name}",
               middle_line: barcode1,
               bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
               round_label_top_line: prefix,
               round_label_bottom_line: barcode1,
               barcode: tube1.ean13_barcode }
  end

  test 'should return correct tubes' do
    assert_equal 1, tube_label.tubes.count
  end

  test 'should return correct top_line value' do
    assert_equal "(p) #{@tube_name}", tube_label.top_line(tube1)
  end
end
