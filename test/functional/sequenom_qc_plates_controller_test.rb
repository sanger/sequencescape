
# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

require 'test_helper'
require 'sdb/sample_manifests_controller'

class SequenomQcPlatesControllerTest < ActionController::TestCase
  context '#create' do
    setup do
      @controller = SequenomQcPlatesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create :manager, barcode: 'ID99A'
      @controller.stubs(:current_user).returns(@user)
    end

    should 'send print request' do
      barcode = mock('barcode')
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      barcode_printer = create :barcode_printer
      LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])

      plate1 = create :plate, barcode: '9168137'
      plate2 = create :plate, barcode: '163993'

      RestClient.expects(:post)

      post :create, 'user_barcode' => (Barcode.human_to_machine_barcode(@user.barcode)).to_s,
                    'input_plate_names' => { '1' => (plate1.ean13_barcode).to_s, '2' => (plate2.ean13_barcode).to_s, '3' => '', '4' => '' },
                    'plate_prefix' => 'QC',
                    'gender_check_bypass' => '1',
                    'barcode_printer' => { 'id' => (barcode_printer.id).to_s },
                    'number_of_barcodes' => '1'
    end
  end
end
