# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StockAssetsController do
  describe 'GET new' do
    let(:current_user) { create :user }

    shared_examples 'an inactive endpoint' do
      it 'returns the user to the batch page with a warning' do
        get :new, { batch_id: batch.id }, user: current_user.id
        expect(response).to redirect_to batch
        expect(flash[:alert]).to eq(warning)
      end
    end

    context 'with an empty batch' do
      let(:batch) { create :batch }
      let(:warning) { 'No requests to create stock tubes' }
      it_behaves_like 'an inactive endpoint'
    end

    context 'with a single plex batch' do
      let(:batch) { create :batch, request_count: 2 }
      let(:library_tube_ids) { batch.reload.requests.map(&:target_asset_id) }

      context 'without a stock tube' do
        it 'renders the form' do
          get :new, { batch_id: batch.id }, user: current_user.id
          expect(assigns(:assets).length).to eq(2)
          assigns(:assets).each do |asset|
            expect(asset.last).to be_a(StockLibraryTube)
          end
          expect(assigns(:assets).keys).to eq(library_tube_ids)
          expect(response).to render_template :new
        end
      end

      context 'with stock tube already existing' do
        before(:each) do
          batch.reload.requests.each { |r| r.target_asset.parents << create(:stock_library_tube) }
        end

        let(:warning) { 'Stock tubes have already been created' }
        it_behaves_like 'an inactive endpoint'
      end
    end

    context 'with a multiplexed batch' do
      let(:batch) { create :multiplexed_batch, request_count: 2 }

      context 'without mx tubes' do
        let(:warning) { "There's no multiplexed library tube available to have a stock tube." }
        it_behaves_like 'an inactive endpoint'
      end

      context 'with mx tubes' do
        let(:multiplexed_library_tube) { create :multiplexed_library_tube }

        before(:each) do
          batch.reload.requests.each do |request|
            request.target_asset.children << multiplexed_library_tube
          end
        end

        context 'without stock tubes' do
          it 'renders the form' do
            get :new, { batch_id: batch.id }, user: current_user.id
            expect(assigns(:assets).length).to eq(1)
            assigns(:assets).each do |asset|
              expect(asset.first).to eq(multiplexed_library_tube.id)
              expect(asset.last).to be_a(StockMultiplexedLibraryTube)
            end
            expect(response).to render_template :new
          end
        end

        context 'with stock tube already existing' do
          before(:each) do
            multiplexed_library_tube.parents << create(:stock_multiplexed_library_tube)
          end

          let(:warning) { 'Stock tubes have already been created' }
          it_behaves_like 'an inactive endpoint'
        end
      end
    end
  end

  describe 'POST create' do
    let(:current_user) { create :user }
    let(:batch) { create :batch }
    let(:library_tube_1) { create :library_tube }
    let(:library_tube_2) { create :library_tube }

    it 'creates the required stock assets' do
      post :create, { batch_id: batch.id, assets: {
        library_tube_1.id => { name: 'My stock 1', volume: '100', concentration: '200' },
        library_tube_2.id => { name: 'My stock 2', volume: '100', concentration: '200' }
      } }, user: current_user.id
      expect(response).to redirect_to(batch)
      expect(flash[:notice]).to eq('2 stock tubes created')
      expect(library_tube_1.reload.parents.first).to be_a(StockLibraryTube)
      expect(library_tube_1.reload.parents.first.barcode).to_not be_nil
    end
  end
end
