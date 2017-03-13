require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe '/api/1/work_completions' do
  include_context 'a limber target plate with submissions'

  subject { '/api/1/work_completions' }

  let(:authorised_app) { create :api_application }
  let(:parent_purpose) { create :plate_purpose }
  let(:user) { create :user }

  context '#post' do
    let(:payload) do
      %{{
        "work_completion":{
          "target": "#{target_plate.uuid}",
          "user": "#{user.uuid}",
          "submissions": ["#{target_submission.uuid}"]
        }
      }}
    end

    let(:response_body) {
      %{{
        "work_completion": {
          "actions": {},
          "target": {
            "uuid": "#{target_plate.uuid}",
            "actions": {}
          },
          "submissions": {
            "size": 1,
            "actions": {}
          },
          "user": {
            "uuid": "#{user.uuid}",
            "actions": {}
          }
        }
      }}
    }
    let(:response_code) { 201 }

    it 'supports resource creation' do
      api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end

    it 'sets submissions correctly' do
      api_request :post, subject, payload
    end
  end
end
