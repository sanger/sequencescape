# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class CreatorTest < ActiveSupport::TestCase
  attr_reader :creator, :barcode_printer

  def setup
    @creator = create :plate_creator
    @barcode_printer = create :barcode_printer
  end

  test 'should send request to print labels' do
    barcode = mock('barcode')
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)

    LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    scanned_user = create :user

    RestClient.expects(:post)

    assert creator.execute('', barcode_printer, scanned_user, Plate::CreatorParameters.new('user_barcode' => '2470000099652', 'source_plates' => '', 'creator_id' => '1', 'dilution_factor' => '1', 'barcode_printer' => '1'))
  end

  test 'should properly create plates' do
    creator_purpose = create :plate_purpose
    child_creator = create :plate_creator, plate_purposes: [creator_purpose]
    barcode = mock('barcode')
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)

    LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(true)

    parent = create :plate_with_untagged_wells
    user = create :user
    plate_count = Plate.count

    child_creator.execute(parent.ean13_barcode, barcode_printer, user)
    assert_equal 1, Plate.count - plate_count
    child = parent.reload.children.first

    assert_equal creator_purpose, child.purpose

    parent.wells.each_with_index do |well, i|
      matching_aliquots = (well.aliquots.first =~ child.wells[i].aliquots.first)
      assert matching_aliquots, "Aliquots do not match in #{well.map_description}"
    end
  end
end
