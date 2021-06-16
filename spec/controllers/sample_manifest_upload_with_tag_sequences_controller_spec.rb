# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestUploadWithTagSequencesController, { type: :controller, with: :uploader } do
  let(:user) { create :user, barcode: 'ID41440E', swipecard_code: '1234567' }

  # - Mock out the call to create the foreign barcode, and 'register_stock!'
  # - Call 'create' in SampleManifestUploadWithTagSequencesController (encompasses the valid? call as well as the process call)
  # - Check that one gets called before the other
  describe '#create' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_manifest_1.csv', 'text/csv') }

    let(:params) { { 'utf8' => '✓', 'upload' => file, 'commit' => 'Upload manifest' } }

    before { post :create, params: params, session: { user: user.id } }

    it 'creates' do
      expect(response.status).to eq 200

      # expect(response.status).to eq 302 # redirect
      expect(flash[:error]).to be_nil
    end
  end
end
