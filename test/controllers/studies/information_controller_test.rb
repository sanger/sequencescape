# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'studies/information_controller'

module Studies
  class InformationControllerTest < ActionController::TestCase
    context 'Studies::Information controller' do
      setup do
        @controller = Studies::InformationController.new
        @request    = ActionController::TestRequest.create(@controller)
        @user = create :user
        session[:user] = @user.id
        @study = create :study
      end

      should_require_login(:show, parent: 'study')

      context '#show' do
        setup do
          get :show, params: { id: 'unused', study_id: @study.id }
        end

        should respond_with :success
        should render_template :show
      end
    end
  end
end
