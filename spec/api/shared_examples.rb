# frozen_string_literal: true

shared_examples 'an API/1 GET endpoint' do
  it 'supports resource reading' do
    api_request :get, subject
    expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
    expect(status).to eq(response_code)
  end
end
