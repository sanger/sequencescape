# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Aker::JobsController, type: :request, aker: true do
  let(:params) { { job: build(:aker_job_json) }.to_h.with_indifferent_access }

  it 'creates a new job' do
    expect do
      post api_v2_aker_jobs_path, params: params
    end.to change(Aker::Job, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it 'returns an error if somebody tries to create an job without job_id' do
    params['job'].delete('job_id')
    expect do
      post api_v2_aker_jobs_path, params: params
    end.to_not change(Aker::Job, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns an error if somebody tries to create an job without data_release_uuid' do
    params['job'].delete('data_release_uuid')
    expect do
      post api_v2_aker_jobs_path, params: params
    end.to_not change(Aker::Job, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns an error if somebody tries to create an job without aker_job_url' do
    params['job'].delete('aker_job_url')
    expect do
      post api_v2_aker_jobs_path, params: params
    end.to_not change(Aker::Job, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end


  it 'returns an error if somebody tries to create an job without materials' do
    params['job'].delete('materials')
    expect do
      post api_v2_aker_jobs_path, params: params
    end.to_not change(Aker::Job, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

end
