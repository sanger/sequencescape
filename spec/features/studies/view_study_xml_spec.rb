# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Study XML view', type: :request do
  let(:user) { create(:user, email: 'login@example.com', password: 'password') }

  let(:study) { create(:study) }

  let(:expected_xml) do
    Rails.root.join('spec/data/studies/study.xml').read
  end

  before { post '/login', params: { login: user.login, password: 'password' } }

  it 'returns the expected study XML' do
    get study_path(study, format: :xml)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/xml')
    expect(response.body).to eq(expected_xml)
  end
end
