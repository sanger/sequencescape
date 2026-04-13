# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchesController do
  let(:zip_data) { 'FAKE ZIP DATA' }
  let(:run_manifest_filename) { "attachment; filename=\"batch_#{batch.id}_run_manifest.zip\"" }

  shared_examples 'returns a run manifest zip file' do
    it 'returns a zip file with the correct filename and content', :aggregate_failures do
      expect(response.content_type).to eq('application/zip')
      expect(response.headers['Content-Disposition']).to include(run_manifest_filename)
      expect(response.body).to eq(zip_data)
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#generate_ultima_sample_sheet' do
    let(:current_user) { create(:user) }
    let(:pipeline) { create(:ultima_sequencing_pipeline) }
    let(:batch) { create(:batch, pipeline:) }

    before do
      allow(UltimaSampleSheet::SampleSheetGenerator).to receive(:generate).with(batch).and_return(zip_data)
    end

    context 'when downloading with login' do
      before do
        get :generate_sample_sheet, params: { id: batch.id }, session: { user: current_user.id }
      end

      it_behaves_like 'returns a run manifest zip file'
    end

    context 'when downloading wihout login' do
      # Test: be able to download the file through an url without auth. (Request from NPG team)
      before do
        get :generate_sample_sheet, params: { id: batch.id }
      end

      it_behaves_like 'returns a run manifest zip file'
    end
  end

  describe '#generate_ultima_ug200_sample_sheet' do
    let(:current_user) { create(:user) }
    let(:pipeline) { create(:ultima_ug200_sequencing_pipeline) }
    let(:batch) { create(:batch, pipeline:) }

    before do
      allow(UltimaSampleSheet::UG200SampleSheetGenerator).to receive(:generate).with(batch).and_return(zip_data)
    end

    context 'when downloading with login' do
      before do
        get :generate_sample_sheet, params: { id: batch.id }, session: { user: current_user.id }
      end

      it_behaves_like 'returns a run manifest zip file'
    end

    context 'when downloading without login' do
      before do
        get :generate_sample_sheet, params: { id: batch.id }
      end

      it_behaves_like 'returns a run manifest zip file'
    end
  end
end
