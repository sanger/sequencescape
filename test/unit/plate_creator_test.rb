#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.

require "test_helper"

class CreatorTest < ActiveSupport::TestCase

	attr_reader :creator

	def setup
		@creator = create :plate_creator, plate_purpose: PlatePurpose.find_by_name("Stock plate")
	end

	test "should send request to print labels" do

		barcode = mock("barcode")
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)

    barcode_printer = create :barcode_printer
    LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns({'data' => [{'id' => 15}]})
		scanned_user = create :user

    RestClient.expects(:post)

		creator.execute("", barcode_printer, scanned_user, Plate::CreatorParameters.new({"user_barcode"=>"2470000099652", "source_plates"=>"", "creator_id"=>"1", "dilution_factor"=>"1", "barcode_printer"=>"1"}))
	end

end