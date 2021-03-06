# frozen_string_literal: true

require 'test_helper'

class CreatorTest < ActiveSupport::TestCase
  attr_reader :creator, :barcode_printer

  def setup
    @creator_purpose = create :plate_purpose
    @creator = create :plate_creator, plate_purposes: [@creator_purpose]
    @barcode_printer = create :barcode_printer
  end

  test 'should send request to print labels' do
    barcode = create(:barcode)
    PlateBarcode.stubs(:create).returns(barcode)

    LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    scanned_user = create :user
    create_asset_group = 'No'

    RestClient.expects(:post)

    assert creator.execute(
             '',
             barcode_printer,
             scanned_user,
             create_asset_group,
             Plate::CreatorParameters.new(
               'user_barcode' => '2470000099652',
               'source_plates' => '',
               'creator_id' => '1',
               'dilution_factor' => '1',
               'barcode_printer' => '1'
             )
           )
  end

  test 'should properly create plates' do
    barcode = create(:plate_barcode)
    PlateBarcode.stubs(:create).returns(barcode)

    LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(true)

    parent = create :plate_with_untagged_wells
    user = create :user
    plate_count = Plate.count
    create_asset_group = 'No'

    @creator.execute(parent.machine_barcode, barcode_printer, user, create_asset_group)
    assert_equal 1, Plate.count - plate_count
    child = parent.reload.children.first

    assert_equal @creator_purpose, child.purpose

    parent.wells.each_with_index do |well, i|
      matching_aliquots = well.aliquots.first.matches?(child.wells[i].aliquots.first)
      assert matching_aliquots,
             "Aliquots do not match in #{well.map_description}: #{well.aliquots.first} !~= #{child.wells[i].aliquots.first}"
    end
  end

  test 'should maintain barcode number for different prefixes with sanger barcodes' do
    LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(true)

    parent = create :plate_with_untagged_wells, sanger_barcode: { prefix: 'AA', number: '123000' }
    user = create :user
    create_asset_group = 'No'

    @creator.execute(parent.machine_barcode, barcode_printer, user, create_asset_group)
    child = parent.reload.children.first

    assert_equal child.human_barcode, 'DN123000K'
  end

  test 'should change barcode number for different prefixes with non-sanger barcodes' do
    LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(true)
    barcode = create(:plate_barcode)
    PlateBarcode.stubs(:create).returns(barcode)

    parent = create :plate_with_untagged_wells, barcodes: create_list(:heron_tailed, 1, number: 123_000)
    user = create :user
    create_asset_group = 'No'

    @creator.execute(parent.machine_barcode, barcode_printer, user, create_asset_group)
    child = parent.reload.children.first

    # We expect it to generate a new barcode"
    assert_equal SBCF::SangerBarcode.new(prefix: 'DN', number: barcode.barcode).human_barcode, child.human_barcode
  end
end
