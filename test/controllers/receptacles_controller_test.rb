# frozen_string_literal: true

require 'test_helper'

class ReceptaclesControllerTest < ActionController::TestCase
  setup do
    @controller = ReceptaclesController.new
    @request = ActionController::TestRequest.create(@controller)
    @user = create(:admin, api_key: 'abc')
    session[:user] = @user.id
  end

  should_require_login

  context 'create request with JSON input' do
    setup do
      @submission_count = Submission.count
      @asset = create(:sample_tube).receptacle
      @sample = @asset.primary_aliquot.sample

      @study = create(:study)
      @project = create(:project, enforce_quotas: true)
      @request_type = create(:request_type)
      @json_data = valid_json_create_request(@asset, @request_type, @study, @project)

      @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
      post :create_request, params: ActiveSupport::JSON.decode(@json_data)
    end

    should 'change Submission.count by 1' do
      assert_equal 1, Submission.count - @submission_count, 'Expected Submission.count to change by 1'
    end
    should 'set a priority' do
      assert_equal(3, Submission.last.priority)
    end
  end

  def valid_json_create_request(asset, request_type, study, project) # rubocop:todo Metrics/MethodLength
    "
      {
        \"api_version\": \"#{RELEASE.api_version}\",
        \"api_key\": \"abc\",
        \"study_id\": \"#{study.id}\",
        \"project_id\": \"#{project.id}\",
        \"request_type_id\": \"#{request_type.id}\",
        \"count\": 3,
        \"priority\": 3,
        \"comments\": \"This is a request\",
        \"id\": \"#{asset.id}\",
        \"request\": {
          \"properties\": {
            \"library_type\": \"Standard\",
            \"fragment_size_required_from\": 100,
            \"fragment_size_required_to\": 500,
            \"read_length\": 108
          }
        }
      }
    "
  end
end
