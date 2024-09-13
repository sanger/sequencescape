# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a POST request with a disallowed attribute' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with bad_request' do
    expect(response).to have_http_status(:bad_request)
  end

  it 'specifies which attribute was not allowed' do
    expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_attribute} is not allowed.")
  end
end

shared_examples 'an unprocessable POST request with a specific error' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with unprocessable_entity' do
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'specifies which relationship must exist' do
    expect(json.dig('errors', 0, 'detail')).to eq(error_detail_message)
  end
end

shared_examples 'a POST request including a has_one relationship' do
  before { api_get "#{base_endpoint}/#{resource.id}?include=#{related_name}" }

  it 'responds with a success http code' do
    expect(response).to have_http_status(:success)
  end

  it 'returns the expected relationship' do
    related = json['included'].find { |i| i['type'] == related_type }
    expect(related['id']).to eq(resource.send(related_name).id.to_s)
    expect(related['type']).to eq(related_type)
  end
end
