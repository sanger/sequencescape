# frozen_string_literal: true

require 'test_helper'

module Api
  class SubmissionsControllerTest < ActionController::TestCase
    context 'submission' do
      setup do
        @controller = Api::SubmissionsController.new
        @request = ActionController::TestRequest.create(@controller)
        @user = FactoryBot.create(:user)
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id
      end

      context '#create' do
        setup do
          @submission_count = Submission.count
          template = FactoryBot.create(:submission_template)
          study = FactoryBot.create(:study)
          project = FactoryBot.create(:project)
          sample_tube = FactoryBot.create(:sample_tube)
          rt = FactoryBot.create(:request_type)
          template.request_types << rt

          post :create,
               params: {
                 order: {
                   project_id: project.id,
                   study_id: study.id,
                   sample_tubes: [sample_tube.id.to_s],
                   number_of_lanes: '2',
                   type: template.key
                 }
               }
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
end
