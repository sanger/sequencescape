# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Api::V2::Aker::JobsController, type: :request, aker: true do
  include BarcodeHelper
  before do
    mock_plate_barcode_service
    @purpose = FactoryBot.create :aker_plate_purpose
  end

  context 'when there is one job in the message' do
    let(:params) { { data: [{ attributes: build(:aker_job_json) }] }.to_h.with_indifferent_access }

    it 'creates a new job' do
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to change(Aker::Job, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns an error if somebody tries to create an job without job_id' do
      params['data'][0]['attributes'].delete('job_id')
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to_not change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without data_release_uuid' do
      params['data'][0]['attributes'].delete('data_release_uuid')
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to_not change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without aker_job_url' do
      params['data'][0]['attributes'].delete('aker_job_url')
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to_not change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without job_uuid' do
      params['data'][0]['attributes'].delete('job_uuid')
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to_not change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end    

    it 'returns an error if somebody tries to create an job without materials' do
      params['data'][0]['attributes'].delete('materials')
      expect do
        post api_v2_aker_jobs_path, params: params
      end.to_not change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when there is more than one job in the message' do
    context 'when both jobs are valid' do
      let(:job1) { build(:aker_job_json) }
      let(:job2) { build(:aker_job_json) }
      let(:params) { { data: [{ attributes: job1 }, { attributes: job2 }] }.to_h.with_indifferent_access }

      it 'creates two new jobs' do
        expect do
          post api_v2_aker_jobs_path, params: params
        end.to change(Aker::Job, :count).by(2)
        expect(response).to have_http_status(:created)
      end
    end
    context 'when only one job is valid' do
      let(:job1) { build(:aker_job_json) }
      let(:job2) { build(:aker_job_json) }
      let(:params) { { data: [{ attributes: job1 }, { attributes: job2 }] }.to_h.with_indifferent_access }

      it 'returns an error' do
        params['data'][0]['attributes'].delete('job_id')
        expect do
          post api_v2_aker_jobs_path, params: params
        end.to_not change(Aker::Job, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

  end

end
