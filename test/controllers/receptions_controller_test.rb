# frozen_string_literal: true

require 'test_helper'
class ReceptionsControllerTest < ActionController::TestCase
  context 'Sample Reception' do
    setup do
      @controller = ReceptionsController.new
      @request    = ActionController::TestRequest.create(@controller)
      @user = FactoryBot.create :user
      session[:user] = @user.id
      @plate = FactoryBot.create :plate
      @sample_tube = FactoryBot.create :sample_tube
    end

    should_require_login

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

    context '#index' do
      setup do
        @asset_count = Asset.count
        get :index, params: { id: @plate.id }
      end

      should respond_with :success

      should 'change Asset.count by 0' do
        assert_equal 0, Asset.count - @asset_count, 'Expected Asset.count to change by 0'
      end
    end
  end
end
