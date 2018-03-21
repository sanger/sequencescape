# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
class ReceptionsControllerTest < ActionController::TestCase
  context 'Sample Reception' do
    setup do
      @controller = ReceptionsController.new
      @request    = ActionController::TestRequest.create(@controller)
      @user = FactoryGirl.create :user
      session[:user] = @user.id
      @plate = FactoryGirl.create :plate
      @sample_tube = FactoryGirl.create :sample_tube
    end

    should_require_login

    context '#import_from_snp' do
      context 'with 1 plate' do
        setup do
          @plate_count = Plate.count
          post :import_from_snp, params: { snp_plates: { '1' => '1234' } }
        end

        should 'change Plate.count by 1' do
          assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
        end
        should respond_with :redirect
        should set_flash.to(/queued to be imported/)
      end

      context 'with 3 plates' do
        setup do
          @plate_count = Plate.count
          post :import_from_snp, params: { snp_plates: { '1' => '1234', '5' => '7654', '10' => '3456' } }
        end

        should 'change Plate.count by 3' do
          assert_equal 3, Plate.count - @plate_count, 'Expected Plate.count to change by 3'
        end
        should respond_with :redirect
        should set_flash.to(/queued to be imported/)
      end

      context 'with 3 plates plus blanks' do
        setup do
          @plate_count = Plate.count
          post :import_from_snp, params: { snp_plates: { '1' => '1234', '7' => '', '5' => '7654', '2' => '', '10' => '3456' } }
        end

        should 'change Plate.count by 3' do
          assert_equal 3, Plate.count - @plate_count, 'Expected Plate.count to change by 3'
        end
        should respond_with :redirect
        should set_flash.to(/queued to be imported/)
      end
    end

    context '#confirm reception' do
      context 'where asset exists' do
        setup do
          @asset_count = Asset.count
          @event_count = Event.count
          post :confirm_reception, params: { asset_id: { '0' => @plate.id } }
        end

        should 'change Asset.count by 0' do
          assert_equal 0, Asset.count - @asset_count, 'Expected Asset.count to change by 0'
        end

        should 'change Event.count by 1' do
          assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
        end

        should respond_with :success

        should 'create a broadcast event' do
          assert BroadcastEvent::LabwareReceived.find_by(seed: @plate).present?, 'No event created'
        end
      end

      context 'where asset doesnt exist' do
        setup do
          @asset_count = Asset.count
          post :confirm_reception, params: { asset_id: { '0' => 999999 } }
        end

        should 'change Asset.count by 0' do
          assert_equal 0, Asset.count - @asset_count, 'Expected Asset.count to change by 0'
        end
        should set_flash.to(/not found/)
      end
    end

    ['index', 'snp_import'].each do |controller_method|
      context "##{controller_method}" do
        setup do
          @asset_count = Asset.count
          get controller_method, params: { id: @plate.id }
        end

        should respond_with :success

        should 'change Asset.count by 0' do
          assert_equal 0, Asset.count - @asset_count, 'Expected Asset.count to change by 0'
        end
      end
    end
  end
end
