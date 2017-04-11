# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class Api::SubmissionsControllerTest < ActionController::TestCase
  context 'submission' do
    setup do
      @controller = Api::SubmissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :user
      @controller.stubs(:logged_in?).returns(@user)
      session[:user] = @user.id
    end

    context '#create' do
      setup do
        @submission_count = Submission.count
        template = FactoryGirl.create :submission_template
        study = FactoryGirl.create :study
        project = FactoryGirl.create :project
        sample_tube = FactoryGirl.create :sample_tube
        workflow = FactoryGirl.create :submission_workflow, id: 1 # Submission needs a workflow
        rt = FactoryGirl.create :request_type, workflow: workflow
        template.request_types << rt

        post :create, order: { project_id: project.id, study_id: study.id, sample_tubes: [sample_tube.id.to_s], number_of_lanes: '2', type: template.key }
      end

      should 'change Submission.count by 1' do
        assert_equal 1, Submission.count - @submission_count, 'Expected Submission.count to change by 1'
      end

      should 'output a correct error message' do
        assert_equal '"Submission created"', @response.body
      end
    end
  end
end
