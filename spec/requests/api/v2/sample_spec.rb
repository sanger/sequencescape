# frozen_string_literal: true
require 'rails_helper'

describe 'Samples API', with: :api_v2, cardinal: true do
  context 'when creating a sample' do
    it 'can create a new sample' do
      api_post '/api/v2/samples', { data: { type: 'samples', attributes: { name: 'sample_1' } } }
      sample = Sample.find_by(name: 'sample_1')
      expect(sample).to be_a_kind_of(Sample)
    end
  end
end
