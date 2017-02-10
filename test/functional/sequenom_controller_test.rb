# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class SequenomControllerTest < ActionController::TestCase
  should_require_login

  should route(:get, '/sequenom/index').to(controller: 'sequenom', action: 'index')
  should route(:post, '/sequenom/search').to(controller: 'sequenom', action: 'search')
  should route(:get, '/sequenom/12345').to(controller: 'sequenom', action: 'show', id: '12345')
  should route(:put, '/sequenom/12345').to(controller: 'sequenom', action: 'update', id: '12345')

  context 'when logged in' do
    setup do
      user = FactoryGirl.create :user
      @controller.stubs(:logged_in?).returns(user)
      @controller.stubs(:current_user).returns(user)
    end

    teardown do
      Plate.destroy_all
    end

    context "GET 'index'" do
      setup do
        get :index
      end

      should render_template :index
      should_have_a_form_to('#sequenom_search') { sequenom_search_path }

      should 'have a field for the plate barcode' do
        assert_select 'form#sequenom_search input[name=plate_barcode]'
      end

      should 'have a search submission button' do
        assert_select 'form#sequenom_search input[type=submit]'
      end
    end

    context "POST 'search'" do
      context 'when the plate barcode does not exist' do
        setup do
          post :search, plate_barcode: '1220099999705'
        end

        should 'create the non-existent plate in the database' do
          assert_not_nil Plate.find_by(barcode: '99999')
        end

        should 'redirect to the Sequenom plate view' do
          assert_redirected_to sequenom_plate_path(Plate.find_by(barcode: '99999'))
        end
      end

      context 'when the plate barcode does exist' do
        setup do
          @plate = FactoryGirl.create(:plate, barcode: '99999')
          post :search, plate_barcode: '1220099999705'
        end

        should 'redirect to the Sequenom plate view' do
          assert_redirected_to sequenom_plate_path(@plate)
        end
      end

      context 'when the user barcode is not entered' do
        setup do
          post :search
        end

        should 'redirect to the Sequenom homepage' do
          assert_redirected_to sequenom_root_path
        end

        should 'set the flash[:error] information' do
          assert_equal 'You appear to have forgotten to scan the plate barcode', flash[:error]
        end
      end
    end

    context "PUT 'update'" do
      context 'when the plate does not exist' do
        setup do
          user = FactoryGirl.create(:user)
          put :update, id: '12345', sequenom_step: SequenomController::STEPS.first.name, user_barcode: user.barcode
        end

        should 'redirect to the Sequenom homepage' do
          assert_redirected_to sequenom_root_path
        end

        should 'set the flash[:error] information' do
          assert_equal 'The plate you requested does not appear to exist', flash[:error]
        end
      end

      context 'when the user does not exist' do
        setup do
          @plate = FactoryGirl.create(:plate)
          post :update, id: @plate.id, sequenom_step: SequenomController::STEPS.first.name, user_barcode: '2470099999680'
        end

        should 'redirect to the Sequenom homepage' do
          assert_redirected_to sequenom_root_path
        end

        should 'set the flash[:error] information' do
          assert_equal 'There appears to be no user with barcode 2470099999680 (ID99999D)', flash[:error]
        end
      end

      context 'when the user barcode is not entered' do
        setup do
          @plate = FactoryGirl.create(:plate)
          post :update, id: @plate.id, sequenom_step: SequenomController::STEPS.first.name
        end

        should 'redirect to the Sequenom homepage' do
          assert_redirected_to sequenom_root_path
        end

        should 'set the flash[:error] information' do
          assert_equal 'You appear to have forgotten to scan your barcode', flash[:error]
        end
      end

      context 'when the plate exists' do
        SequenomController::STEPS.each do |step|
          context "and marking '#{step.name}' completed" do
            setup do
              @plate, @user = FactoryGirl.create(:plate), FactoryGirl.create(:user, barcode: 'ID99999D')
              post :update, id: @plate.id, sequenom_step: step.name, user_barcode: '2470099999680'
            end

            teardown do
              @plate.events.destroy_all
              @plate.destroy
              @user.destroy
            end

            should 'redirect to the Sequenom plate view' do
              assert_redirected_to sequenom_plate_path(@plate)
            end

            should 'add the Sequenom step completed event' do
              assert_not_nil Plate.find(@plate.id).events.find_by(message: "#{step.name} step completed", created_by: @user.login)
            end
          end
        end
      end
    end

    context "GET 'show'" do
      context 'when the plate does not exist' do
        setup do
          get :show, id: '12345'
        end

        should 'redirect to the Sequenom homepage' do
          assert_redirected_to sequenom_root_path
        end

        should 'set the flash[:error] information' do
          assert_equal 'The plate you requested does not appear to exist', flash[:error]
        end
      end

      context 'when the plate exists' do
        setup do
          @plate = FactoryGirl.create(:plate)
          get :show, id: @plate.id
        end

        should render_template :show
        should_have_a_form_to('#sequenom_update') { sequenom_update_path(@plate) }

        should 'have a dropdown with the Sequenom steps' do
          assert_select 'form#sequenom_update select' do
            SequenomController::STEPS.each do |step|
              assert_select 'option[value=?]', step.name
            end
          end
        end

        should 'have a field for user barcode' do
          assert_select 'form#sequenom_update input[name=user_barcode]'
        end
      end
    end
  end
end
