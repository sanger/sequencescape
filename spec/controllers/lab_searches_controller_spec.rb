# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabSearchesController do
  let(:current_user) { create :user }

  it_behaves_like 'it requires login'

  context 'searching (when logged in)' do
    let!(:asset) { create(:sample_tube, name: 'FindMeAsset') }
    let!(:other_asset) { create(:sample_tube) }
    let!(:batch) { create :batch, user: current_user }

    describe '#new' do
      setup { get :new, params: { q: query }, session: { user: current_user.id } }

      context 'with an asset name' do
        let(:query) { 'FindMe' }

        it 'finds assets by name' do
          expect(assigns(:assets)).to include(asset)
        end
      end

      context 'with a batch id' do
        # We pad to meet the minimum query length.
        let(:query) { "#{batch.id}  " }

        it 'finds the batch' do
          expect(assigns(:batches)).to include(batch)
        end
      end

      context 'with a user login' do
        let(:query) { current_user.login }

        it 'finds batches by owner' do
          expect(assigns(:batches)).to include(batch)
        end
      end

      context 'With an ean13 barcode' do
        let(:query) { asset.ean13_barcode }

        it 'finds the asset' do
          expect(assigns(:assets)).to include(asset)
        end

        it 'does not find other assets' do
          expect(assigns(:assets)).not_to include(other_asset)
        end
      end

      context 'With an human barcode' do
        let(:query) { asset.human_barcode }

        it 'finds the asset' do
          expect(assigns(:assets)).to include(asset)
        end

        it 'does not find other assets' do
          expect(assigns(:assets)).not_to include(other_asset)
        end
      end

      context 'with a plate barcode' do
        let(:asset) { create :plate }
        let(:query) { asset.human_barcode }

        it 'finds the asset' do
          expect(assigns(:assets)).to include(asset)
        end

        it 'does not find other assets' do
          expect(assigns(:assets)).not_to include(other_asset)
        end
      end
    end
  end
end
