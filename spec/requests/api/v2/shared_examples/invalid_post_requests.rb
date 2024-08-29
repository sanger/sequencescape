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

  it 'specifies which attribute was not allowed ' do
    expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_attribute} is not allowed.")
  end
end

shared_examples 'a POST request with a missing attribute' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with unprocessable_entity' do
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'specifies which attribute was not allowed ' do
    expect(json.dig('errors', 0, 'detail')).to eq("#{missing_attribute} - can't be blank")
  end
end

shared_examples 'a POST request without a required relationship' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with unprocessable_entity' do
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'specifies which attribute was not allowed ' do
    expect(json.dig('errors', 0, 'detail')).to eq("#{missing_relationship} - must exist")
  end
end
