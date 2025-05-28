# frozen_string_literal: true
require 'rails_helper'

# For more complete tests, see spec/features/sample_manifests/uploader_for_manifests_with_tag_sequences_spec.rb

RSpec.describe SampleManifestUploadWithTagSequencesController, type: :controller do
  let(:user) { create(:user) }
  let(:upload_file) { 'pretend-this-is-an-actual-file' }
  let(:uploader) { instance_double(SampleManifest::Uploader, run!: true, study: nil) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(SampleManifest::Uploader).to receive(:new).and_return(uploader)
  end

  describe 'POST #create' do
    context 'when no file is attached' do
      before { post :create, params: { upload: nil } }

      it 'sets an error flash message' do
        expect(flash[:error]).to eq('No file attached')
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    context 'when the file is uploaded successfully' do
      before { post :create, params: { upload: upload_file } }

      it 'sets a success flash message' do
        expect(flash[:notice]).to eq('Sample manifest successfully uploaded.')
      end

      it 'redirects to the appropriate path' do
        expect(response).to redirect_to(sample_manifests_path)
      end
    end

    context 'when the upload fails due to invalid data' do
      before do
        allow(uploader).to receive(:run!).and_raise(Sample::AccessionValidationFailed, 'Invalid data')
        post :create, params: { upload: upload_file }
      end

      it 'sets an error flash message' do
        expect(flash[:error]).to eq(
          'Your sample manifest contained invalid data and could not be uploaded: Invalid data'
        )
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    context 'when the upload fails for other reasons' do
      before do
        allow(uploader).to receive(:run!).and_return(false)
        post :create, params: { upload: upload_file }
      end

      it 'sets an error flash message' do
        expect(flash[:error]).to eq('Your sample manifest couldn\'t be uploaded.')
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end
  end
end
