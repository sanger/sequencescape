#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"
class LabwhereReceptionsControllerTest < ActionController::TestCase

  MockResponse = Struct.new(:valid?,:error)

  context "Sample Reception" do
    setup do
      @controller = LabwhereReceptionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user, :barcode => 'ID123', :swipecard_code=>'02face'
      @other_user = Factory :user, :barcode => 'ID123', :swipecard_code=>'02face'
      @plate   = Factory :plate, :barcode => 1
      @plate_2 = Factory :plate, :barcode => 2
      @sample_tube = Factory :sample_tube, :barcode => 1
      @location = Factory :location
    end

    context "#create" do
      context 'with multiple assets' do

        setup do
          LabWhereClient::Scan.expects(:create).with(
            :location_barcode=>'labwhere_location',:user_code=>'ID123',:labware_barcodes=>["1220000001831","1220000002845","3980000001795" ]
          ).returns(MockResponse.new(true,''))

          post :create, { :labwhere_reception =>{
            :barcodes => {"1" => "1220000001831", "2" => " 1220000002845 ", "3" => "3980000001795" },
            :location_id => @location.id,
            :user_code => 'ID123',
            :location_barcode => 'labwhere_location'
          }}
        end

        should 'Move items in sequencescape' do
          [@plate,@plate_2,@sample_tube].each do |asset|
            asset.reload
            assert_equal @location, asset.location, "Did not move #{asset}"
          end
        end

        should 'Create reception events' do
          [@plate,@plate_2,@sample_tube].each do |asset|
            assert_equal Event::ScannedIntoLabEvent, asset.events.last.class
            assert_equal "Scanned into #{@location.name}", asset.events.last.message
          end
        end

        should_set_the_flash_to "Locations updated!"
        should_redirect_to('labwhere_receptions') { '/labwhere_receptions' }
      end

      context 'with missing assets' do
        setup do
          post :create, { :labwhere_reception =>{
            :barcodes => {"1" => "1220000001831", "2" => "1220000044838", "3" => "3980000001795" },
            :location_id => @location.id,
            :user_code => 'ID123',
            :location_barcode => 'labwhere_location'
          }}
        end

        should 'Not move anything' do
          [@plate,@plate_2,@sample_tube].each do |asset|
            asset.reload
            assert @location != asset.location, "Did move #{asset} (But shouldn't have done)"
          end
        end

        should 'NOt create an event' do
          [@plate,@plate_2,@sample_tube].each do |asset|
            assert asset.events.empty?
          end
        end

       should_set_the_flash_to "Could not find labware 1220000044838 in Sequencescape"
       should_redirect_to('labwhere_receptions') { '/labwhere_receptions' }
      end
    end

  end

end
