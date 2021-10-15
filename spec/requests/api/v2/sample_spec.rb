# frozen_string_literal: true
require 'rails_helper'

describe 'Samples API', with: :api_v2, cardinal: true do
  context 'when creating a compound sample' do
    let(:component_samples) { create_list(:sample, 5) }

    it 'can create a new sample' do
      api_post '/api/v2/samples', { data: { type: 'samples', attributes: { name: 'compound_sample_1' } } }
      compound_sample = Sample.find_by(name: 'compound_sample_1')
      expect(compound_sample).to be_a_kind_of(Sample)
    end

    context 'when attaching components to a compound sample' do
      let(:compound_sample) { create :sample }
      let(:component_samples_payload) do
        component_samples.each_with_index.map { |s, _pos| { type: 'samples', id: s.id } }
      end

      it 'can attach the component samples using the relation link' do
        api_post "/api/v2/samples/#{compound_sample.id}/relationships/component_samples",
                 { data: component_samples_payload }

        expect(response).to have_http_status(:success)
        expect(compound_sample.component_samples).to eq(component_samples)
      end

      it 'can attach the component samples using the relationship attribute' do
        api_patch "/api/v2/samples/#{compound_sample.id}",
                  {
                    data: {
                      id: compound_sample.id,
                      type: 'samples',
                      relationships: {
                        component_samples: {
                          data: component_samples_payload
                        }
                      }
                    }
                  }

        expect(response).to have_http_status(:success)
        expect(compound_sample.component_samples).to eq(component_samples)
      end

      context 'when providing sample_compound_component_data' do
        let(:assets) { component_samples.map { create :well } }
        let(:target_assets) { component_samples.map { create :well } }
        let(:sample_compound_component_data_payload) do
          component_samples.each_with_index.map do |s, pos|
            { asset_id: assets[pos].id, target_asset_id: target_assets[pos].id, sample_id: s.id }
          end
        end

        it 'can create the linking beteween assets specified' do
          api_patch "/api/v2/samples/#{compound_sample.id}",
                    {
                      data: {
                        id: compound_sample.id,
                        type: 'samples',
                        relationships: {
                          component_samples: {
                            data: component_samples_payload
                          }
                        }
                      }
                    }
          expect(response).to have_http_status(:success)
          expect(compound_sample.component_samples).to eq(component_samples)

          api_patch "/api/v2/samples/#{compound_sample.id}",
                    {
                      data: {
                        id: compound_sample.id,
                        type: 'samples',
                        attributes: {
                          sample_compound_component_data: sample_compound_component_data_payload
                        }
                      }
                    }

          expect(response).to have_http_status(:success)
          
          expect(compound_sample.component_samples).to eq(component_samples)
          sample_compound_component_data_payload.each_with_index do |elem, idx|
            expect(elem[:asset_id]).to eq(compound_sample.joins_as_compound_sample[idx].asset_id)
            expect(elem[:target_asset_id]).to eq(compound_sample.joins_as_compound_sample[idx].target_asset_id)
          end
        end
      end
    end
  end
end
