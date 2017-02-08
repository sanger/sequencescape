# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'studies/workflows_controller'

class Studies::WorkflowsControllerTest < ActionController::TestCase
  context 'Studies::Workflows controller' do
    setup do
      @controller = Studies::WorkflowsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @workflow = create :submission_workflow
      @user     = create :user, workflow_id: @workflow.id
      session[:user] = @user.id
      @study = create :study
    end

    should_require_login(:show)

     context '#show' do
        setup do
          get :show, id: @workflow.id, study_id: @study.id
        end

        should respond_with :success
        should render_template :show
     end
  end
end
