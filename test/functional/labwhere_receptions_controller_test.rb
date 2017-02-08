# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'
class LabwhereReceptionsControllerTest < ActionController::TestCase
  MockResponse = Struct.new(:valid?, :error)

  context 'Sample Reception' do
    setup do
      @controller = LabwhereReceptionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = create :user, barcode: 'ID123', swipecard_code: '02face'
      @other_user = create :user, barcode: 'ID123', swipecard_code: '02face'
      @plate   = create :plate, barcode: 1
      @plate_2 = create :plate, barcode: 2
      @sample_tube = create :sample_tube, barcode: 1
      @location = create :location
    end

    context '#create' do
      context 'with multiple assets' do
        setup do
          LabWhereClient::Scan.expects(:create).with(
            location_barcode: 'labwhere_location', user_code: 'ID123', labware_barcodes: ['1220000001831', '1220000002845', '3980000001795']
          ).returns(MockResponse.new(true, ''))

          post :create, labwhere_reception: {
            barcodes: { '1' => '1220000001831', '2' => ' 1220000002845 ', '3' => '3980000001795' },
            location_id: @location.id,
            user_code: 'ID123',
            location_barcode: 'labwhere_location'
          }
        end

        should 'Move items in sequencescape' do
          [@plate, @plate_2, @sample_tube].each do |asset|
            asset.reload
            assert_equal @location, asset.location, "Did not move #{asset}"
          end
        end

        should 'Create reception events' do
          [@plate, @plate_2, @sample_tube].each do |asset|
            assert_equal Event::ScannedIntoLabEvent, asset.events.last.class
            assert_equal "Scanned into #{@location.name}", asset.events.last.message
          end
        end

        should set_flash.to 'Locations updated!'
        should redirect_to('labwhere_receptions') { '/labwhere_receptions' }
      end

      context 'with no location' do
        setup do
          LabWhereClient::Scan.expects(:create).with(
            location_barcode: '', user_code: 'ID123', labware_barcodes: ['1220000001831', '1220000002845', '3980000001795']
          ).returns(MockResponse.new(true, ''))

          post :create, labwhere_reception: {
            barcodes: { '1' => '1220000001831', '2' => ' 1220000002845 ', '3' => '3980000001795' },
            location_id: @location.id,
            user_code: 'ID123',
            location_barcode: ''
          }
        end

        should 'Move items in sequencescape' do
          [@plate, @plate_2, @sample_tube].each do |asset|
            asset.reload
            assert_equal @location, asset.location, "Did not move #{asset}"
          end
        end

        should 'Create reception events' do
          [@plate, @plate_2, @sample_tube].each do |asset|
            assert_equal Event::ScannedIntoLabEvent, asset.events.last.class
            assert_equal "Scanned into #{@location.name}", asset.events.last.message
          end
        end

        should set_flash.to 'Locations updated!'
        should redirect_to('labwhere_receptions') { '/labwhere_receptions' }
      end
    end
  end
end
