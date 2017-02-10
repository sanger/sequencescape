# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'admin/studies_controller'

class Admin::StudiesControllerTest < ActionController::TestCase
  context 'Studies controller' do
    setup do
      @controller = Admin::StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context 'management UI' do
      setup do
        @user = FactoryGirl.create :admin
        @study = FactoryGirl.create :study
        @request_type = FactoryGirl.create :request_type
        session[:user] = @user.id
        @emails = ActionMailer::Base.deliveries
        @emails.clear
      end

      context '#managed_update (without changes)' do
        setup do
          get :managed_update, id: @study.id, study: { name: @study.name, reference_genome_id: @study.reference_genome_id }
        end

        should 'not send an email' do
          assert_equal [], @emails
        end

        should redirect_to('admin studies path') { "/admin/studies/#{@study.id}" }
      end

      should "change 'ethically_approved' only if user has data_access_coordinator role" do
        put :managed_update, id: @study.id, study: { name: @study.name, ethically_approved: '1' }
        @study.reload
        refute @study.ethically_approved

        @user.roles << (create :data_access_coordinator_role)
        put :managed_update, id: @study.id, study: { name: @study.name, ethically_approved: '1' }
        @study.reload
        assert @study.ethically_approved
      end
    end
  end
end
