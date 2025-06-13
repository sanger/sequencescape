# frozen_string_literal: true

require 'test_helper'

class CreatorTest < ActiveSupport::TestCase
  attr_reader :creator, :barcode_printer

  def setup
    @creator_purpose = create(:plate_purpose)
    @creator = create(:plate_creator, plate_purposes: [@creator_purpose])
    @barcode_printer = create(:barcode_printer)
  end

  test 'should send request to print labels' do
    PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode))

    scanned_user = create(:user)
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
    barcode = 'SQPD-12345'
    PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-12345'))
    PlateBarcode.stubs(:create_child_barcodes).returns([build(:child_plate_barcode, parent_barcode: barcode)])

    LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(true)

    parent = create(:plate_with_untagged_wells)
    user = create(:user)
    plate_count = Plate.count
    create_asset_group = 'No'

    @creator.execute(parent.machine_barcode, barcode_printer, user, create_asset_group)
    assert_equal 1, Plate.count - plate_count
    child = parent.reload.children.first

    assert_equal @creator_purpose, child.purpose

    parent.wells.each_with_index do |well, i|
      matching_aliquots = well.aliquots.first.matches?(child.wells[i].aliquots.first)
      assert matching_aliquots,
             # rubocop:todo Layout/LineLength
             "Aliquots do not match in #{well.map_description}: #{well.aliquots.first} !~= #{child.wells[i].aliquots.first}"
      # rubocop:enable Layout/LineLength
    end
  end

  test 'should fail if source plate has no samples' do
    scanned_source_barcode = 'SQPD-1'
    empty_source_plate = create(:plate, barcode: scanned_source_barcode)

    PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode))

    error =
      assert_raises(StandardError) do
        @creator.send(:validate_plate_is_with_sample, empty_source_plate, scanned_source_barcode)
      end

    assert_match(/No samples were found in the scanned/, error.message)
  end
end
