# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestUploadWithTagSequencesController, { type: :controller, with: :uploader } do
  let(:user) { create :user, barcode: 'ID41440E', swipecard_code: '1234567' }
  let!(:plate) { create :plate_with_empty_wells }
  let(:well1) { plate.wells[0] }
  let(:well2) { plate.wells[1] }
  let(:sample_manifest) { create :sample_manifest }
  let(:sample_manifest_asset1) do
    create :sample_manifest_asset, sample_manifest: sample_manifest, asset: well1, sanger_sample_id: 'SomeTestId'
  end
  let(:sample_manifest_asset2) do
    create :sample_manifest_asset, sample_manifest: sample_manifest, asset: well2, sanger_sample_id: 'SomeTestId2'
  end

  # - Mock out the call to create the foreign barcode, and 'register_stock!'
  # - Call 'create' in SampleManifestUploadWithTagSequencesController (encompasses the valid? call as well as the process call)
  # - Check that one gets called before the other
  describe '#create' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_manifest_1.csv', 'text/csv') }
    let(:params) { { 'utf8' => '✓', 'upload' => file, 'commit' => 'Upload manifest' } }
    let(:action) { post :create, params: params, session: { user: user.id } }

    before do
      sample_manifest_asset1
      sample_manifest_asset2
    end

    it 'does not error' do
      action
      expect(response.status).to eq 302
      expect(flash[:error]).to be_nil
    end

    it 'creates a foreign barcode' do
      expect { action }.to change(Barcode, :count).by(1)
    end

    it 'creates a stock resource Messenger record for each well' do
      expect { action }.to change(Messenger, :count).by(2)
    end

    # doesn't work because of lack of compatibility between 'any_instance_of' and 'ordered'
    # DPL-024 (https://github.com/sanger/unified_warehouse/issues/242)
    # Record created in stock_resource table on manifest upload should refer to the foreign barcode if there is one, rather than the Sanger barcode
    # it 'creates the foreign barcode before registering the stock wells' do
    #   action
    #   expect_any_instance_of(Barcode).to receive(:save)
    #   expect_any_instance_of(Well).to receive(:register_stock!)
    # end
  end
end
