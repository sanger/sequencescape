require 'test_helper'
require_relative 'shared_tests'

class BatchPlateTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedPlateTests

  attr_reader :plate_label, :label, :plate1, :batch, :printable, :pefix, :barcode1, :role, :study_abbreviation, :purpose

  def setup
    study = create :study
    project = create :project
    asset = create :empty_sample_tube
    @role = 'test role'
    @study_abbreviation = 'WTCCC'
    order_role = Order::OrderRole.new role: role

    order = create :order, order_role: order_role, study: study, assets: [asset], project: project
    request = create :well_request, asset: (create :well_with_sample_and_plate), target_asset: (create :well_with_sample_and_plate), order: order

    @batch = create :batch
    batch.requests << request
    @plate1 = batch.plate_group_barcodes.keys[0]
    @purpose = @plate1.purpose.name
    @barcode1 = plate1.barcode
    @printable = { @plate1.barcode => 'on' }
    options = { count: '3', printable: printable, batch: batch }
    @plate_label = LabelPrinter::Label::BatchPlate.new(options)
    @label = { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
               bottom_left: (plate1.sanger_human_barcode).to_s,
               top_right: (study_abbreviation).to_s,
               bottom_right: "#{role} #{purpose} #{barcode1}",
               top_far_right: nil,
               barcode: (plate1.ean13_barcode).to_s }
  end

  test 'should have count' do
    assert_equal 3, plate_label.count
  end

  test 'should have return the right plates' do
    assert_equal [plate1], plate_label.assets
  end

  test 'should return the correct specific values' do
    assert_equal study_abbreviation, plate_label.top_right
    assert_equal "#{role} #{purpose} #{barcode1}", plate_label.bottom_right(plate1)
  end
end
