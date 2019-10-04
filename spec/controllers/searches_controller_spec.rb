# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchesController do
  let(:current_user) { create :user }

  it_behaves_like 'it requires login'

  context 'searching (when logged in)' do
    let!(:study) { create :study, name: 'FindMeStudy' }
    let!(:study2) { create :study, name: 'Another study' }
    let!(:sample) { create :sample, name: 'FindMeSample' }
    let!(:asset) { create(:sample_tube, name: 'FindMeAsset') }
    let!(:other_asset) { create(:sample_tube) }
    let!(:asset_group_to_find) { create :asset_group, name: 'FindMeAssetGroup', study: study }
    let!(:asset_group_to_not_find) { create :asset_group, name: 'IgnoreAssetGroup' }

    let!(:submission) { create :submission, name: 'FindMe' }
    let!(:ignore_submission) { create :submission, name: 'IgnoreMeSub' }

    let!(:sample_with_supplier_name) { create :sample, sample_metadata_attributes: { supplier_name: 'FindMe' } }
    let!(:sample_with_accession_number) { create :sample, sample_metadata_attributes: { sample_ebi_accession_number: 'FindMe' } }

    describe '#index' do
      setup { get :index, params: { q: query }, session: { user: current_user.id } }

      context 'with the valid search' do
        let(:query) { 'FindMe' }

        it { is_expected.to respond_with :success }

        it 'finds the correctly named study' do
          expect(assigns(:studies)).to include(study)
        end

        it 'does not find other studies' do
          expect(assigns(:studies)).not_to include(study2)
        end

        it 'finds the correctly named submission' do
          expect(assigns(:submissions)).to include(submission)
        end

        it 'does not find other submissions' do
          expect(assigns(:submissions)).not_to include(ignore_submission)
        end

        it 'finds the correctly names sample' do
          expect(assigns(:samples)).to include(sample)
        end

        it 'finds samples by supplier name' do
          expect(assigns(:samples)).to include(sample_with_supplier_name)
        end

        it 'finds samples by accession_number' do
          expect(assigns(:samples)).to include(sample_with_accession_number)
        end

        it 'finds labware by name' do
          expect(assigns(:labware)).to include(asset)
        end

        it 'finds asset groups by name' do
          expect(assigns(:asset_groups)).to include(asset_group_to_find)
        end
      end

      context 'with a too short query' do
        let(:query) { 'A' }

        it 'set the flash' do
          expect(flash.now[:error]).to eq 'Queries should be at least 3 characters long'
        end
      end

      context 'With an ean13 barcode' do
        let(:query) { asset.ean13_barcode }

        it 'finds the asset' do
          expect(assigns(:barcodes)).to include(asset.barcodes.first)
        end

        it 'does not find other assets' do
          expect(assigns(:barcodes)).not_to include(other_asset.barcodes.first)
        end
      end

      context 'With an human barcode' do
        let(:query) { asset.human_barcode }

        it 'finds the asset' do
          expect(assigns(:barcodes)).to include(asset.barcodes.first)
        end

        it 'does not find other assets' do
          expect(assigns(:barcodes)).not_to include(other_asset.barcodes.first)
        end
      end
    end
  end
end
