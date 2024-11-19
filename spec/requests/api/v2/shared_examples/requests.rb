# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a POST request with a disallowed value' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with bad_request' do
    expect(response).to have_http_status(:bad_request)
  end

  it 'specifies which value was not allowed' do
    expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_value} is not allowed.")
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

  it 'specifies the expected error message' do
    expect(json.dig('errors', 0, 'detail')).to eq(error_detail_message)
  end
end

shared_examples 'a GET request including a has_one relationship' do |related_name|
  before { api_get "#{base_endpoint}/#{resource.id}?include=#{related_name}" }

  it 'responds with a success http code' do
    expect(response).to have_http_status(:success)
  end

  it "returns the relationship for '#{related_name}'" do
    related = json['data']['relationships'][related_name]['data']
    included = json['included'].map { |i| i.slice('id', 'type') }
    expect(included).to include(related)
  end
end

shared_examples 'a GET request including a has_many relationship' do |related_name|
  before { api_get "#{base_endpoint}/#{resource.id}?include=#{related_name}" }

  it 'responds with a success http code' do
    expect(response).to have_http_status(:success)
  end

  it "returns the relationships for '#{related_name}'" do
    related = json['data']['relationships'][related_name]['data']
    included = json['included'].map { |i| i.slice('id', 'type') }
    expect(included).to include(*related)
  end
end
