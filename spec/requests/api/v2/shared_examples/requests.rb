# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a DESTROY request for a v2 resource' do
  # This shared example tests that the DELETE method is not available for a resource in API v2,
  # when `except: :destroy` is specified in the routes.rb file.
  it 'responds with a routing error' do
    expect { delete "/api/v2/#{resource.model_name.route_key}/#{resource.id}" }.to raise_error(
      ActionController::RoutingError,
      %r{No route matches \[DELETE\] "/api/v2/#{resource.model_name.route_key}/#{resource.id}"}
    )
  end
end

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

shared_examples 'a POST request with a missing parameter' do |missing_parameter|
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with bad_request' do
    expect(response).to have_http_status(:bad_request)
  end

  it 'specifies which parameter is missing' do
    expect(json.dig('errors', 0, 'detail')).to eq("The required parameter, #{missing_parameter}, is missing.")
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

shared_examples 'a bad POST request with a specific error' do
  before { api_post base_endpoint, payload }

  it 'does not create a new resource' do
    expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
  end

  it 'responds with unprocessable_entity' do
    expect(response).to have_http_status(:bad_request)
  end

  it 'specifies the expected error message' do
    expect(json.dig('errors', 0, 'detail')).to eq(error_detail_message)
  end
end

shared_examples 'a GET request including a has_one relationship' do |related_name|
  before { api_get "#{base_endpoint}/#{resource.id}?include=#{related_name}&fields[#{resource_type}]=#{related_name}" }

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
  before { api_get "#{base_endpoint}/#{resource.id}?include=#{related_name}&fields[#{resource_type}]=#{related_name}" }

  it 'responds with a success http code' do
    expect(response).to have_http_status(:success)
  end

  it "returns the relationships for '#{related_name}'" do
    related = json['data']['relationships'][related_name]['data']
    included = json['included'].map { |i| i.slice('id', 'type') }
    expect(included).to include(*related)
  end
end

shared_examples 'a GET request including fetchable attribute' do |attribute_name|
  it "responds with the correct '#{attribute_name}' attribute value" do
    expect(json.dig('data', 'attributes', attribute_name)).to eq(resource.send(attribute_name))
  end
end

shared_examples 'a request excluding unfetchable attribute' do |attribute_name|
  it "excludes unfetchable attribute '#{attribute_name}'" do
    expect(json.dig('data', 'attributes', attribute_name)).not_to be_present
  end
end

shared_examples 'a request referencing a related resource' do |related_name|
  it "returns a reference to the '#{related_name}' relationship" do
    expect(json.dig('data', 'relationships', related_name)).to be_present
  end
end

shared_examples 'a POST request including model attribute' do |model_class, attribute_name|
  it "responds with the new '#{attribute_name}' attribute value" do
    expect(json.dig('data', 'attributes', attribute_name)).to eq(model_class.last.send(attribute_name))
  end
end

shared_examples 'a POST request updating an attribute on the model' do |model_class, attribute_name, value|
  it "updates the model with the new '#{attribute_name}' attribute value" do
    expect(model_class.last.send(attribute_name)).to eq(value)
  end
end

shared_examples 'a POST request updating a relationship on the model' do |model_class, related_name, value|
  it "updates the model with the new '#{related_name}' relationship" do
    expect(model_class.last.send(related_name)).to eq(value)
  end
end

shared_examples 'a PATCH request with a disallowed value' do |disallowed_value|
  def do_patch
    api_patch "#{base_endpoint}/#{resource.id}", payload
  end

  it 'does not modify the resource attributes' do
    # Note that attributes also includes IDs for relationships.
    expect { do_patch }.not_to(change { resource.reload.attributes })
  end

  it 'responds with bad_request' do
    do_patch
    expect(response).to have_http_status(:bad_request)
  end

  it 'specifies which value was not allowed' do
    do_patch
    expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_value} is not allowed.")
  end
end

shared_examples 'it has filtered to a resource with target_id correctly' do
  it 'responds with a success http code' do
    expect(response).to have_http_status(:success)
  end

  it 'returns one resource' do
    expect(json['data'].count).to eq(1)
  end

  it 'returns the correct resource' do
    expect(json['data'].first['id']).to eq(target_id.to_s)
  end
end
