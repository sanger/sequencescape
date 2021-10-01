# frozen_string_literal: true
require 'rails_helper'

describe 'Samples API', with: :api_v2, cardinaldo: true do
  context 'when creating a compound sample' do
    let(:composed_samples) { create_list(:sample, 5) }

    it 'can attach the component samples' do
      composed_samples_payload = composed_samples.each_with_index.map { |s, _pos| { type: 'samples', id: s.id } }

      api_post '/api/v2/samples', { data: { type: 'samples', attributes: { name: 'compound_sample_1' } } }

      compound_sample = Sample.find_by(name: 'compound_sample_1')

      expect(compound_sample).to be_a_kind_of(Sample)

      api_post "/api/v2/samples/#{compound_sample.id}/relationships/component_samples",
               { data: composed_samples_payload }

      expect(response).to have_http_status(:success)
      expect(compound_sample.component_samples).to eq(composed_samples)
    end
  end
end
