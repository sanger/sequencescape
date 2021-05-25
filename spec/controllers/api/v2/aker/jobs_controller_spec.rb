# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Api::V2::Aker::JobsController, type: :request, aker: true do
  include BarcodeHelper
  let(:my_config) do
    '
    sample_metadata.gender              <=   gender
    sample_metadata.donor_id            <=   donor_id
    sample_metadata.supplier_name       <=   supplier_name
    sample_metadata.phenotype           <=   phenotype
    sample_metadata.sample_common_name  <=   common_name
    well_attribute.measured_volume      <=>  volume
    well_attribute.concentration        <=>  concentration
    '
  end

  before do
    mock_plate_barcode_service
    PlatePurpose.stock_plate_purpose

    Aker::Material.config = my_config
  end

  context 'when there is one job in the message' do
    let(:params) { { data: [{ attributes: build(:aker_job_json) }] }.to_h.with_indifferent_access }

    it 'creates a new job' do
      expect { post api_v2_aker_jobs_path, params: params }.to change(Aker::Job, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns an error if somebody tries to create an job without job_id' do
      params['data'][0]['attributes'].delete('job_id')
      expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without data_release_uuid' do
      params['data'][0]['attributes'].delete('data_release_uuid')
      expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without aker_job_url' do
      params['data'][0]['attributes'].delete('aker_job_url')
      expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without job_uuid' do
      params['data'][0]['attributes'].delete('job_uuid')
      expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error if somebody tries to create an job without materials' do
      params['data'][0]['attributes'].delete('materials')
      expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when there is more than one job in the message' do
    context 'when both jobs are valid' do
      let(:job1) { build(:aker_job_json) }
      let(:job2) { build(:aker_job_json) }
      let(:params) { { data: [{ attributes: job1 }, { attributes: job2 }] }.to_h.with_indifferent_access }

      it 'creates two new jobs' do
        expect { post api_v2_aker_jobs_path, params: params }.to change(Aker::Job, :count).by(2)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when only one job is valid' do
      let(:job1) { build(:aker_job_json) }
      let(:job2) { build(:aker_job_json) }
      let(:params) { { data: [{ attributes: job1 }, { attributes: job2 }] }.to_h.with_indifferent_access }

      it 'returns an error' do
        params['data'][0]['attributes'].delete('job_id')
        expect { post api_v2_aker_jobs_path, params: params }.not_to change(Aker::Job, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
