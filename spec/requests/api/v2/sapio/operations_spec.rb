# frozen_string_literal: true

require 'rails_helper'

describe 'Sapio Operations API' do
  let(:base_endpoint) { '/api/v2/sapio/operations' }
  let(:payload) { {} }

  def post_request
    headers = { 'CONTENT_TYPE' => 'application/json' }
    post base_endpoint, params: payload.to_json, headers: headers
  end

  before { post_request }

  it 'returns accepted' do
    expect(response).to have_http_status(:accepted)
  end
end
