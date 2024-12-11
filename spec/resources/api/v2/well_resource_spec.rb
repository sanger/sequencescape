# frozen_string_literal: true

require 'rails_helper'
require './spec/resources/api/v2/shared_examples/receptacle'
require './app/resources/api/v2/well_resource'

RSpec.describe Api::V2::WellResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:well) }

  # Model Name
  it { is_expected.to have_model_name 'Well' }

  # Attributes
  it { is_expected.to have_readonly_attribute :position }

  # Behaviours
  it_behaves_like 'a receptacle resource'

  # Attribute Methods
  describe '#position' do
    context 'off a plate' do
      let(:resource_model) { build_stubbed(:well) }

      it 'returns the position as a hash' do
        expect(resource.position).to eq('name' => nil)
      end
    end

    context 'on a plate' do
      let(:resource_model) { build_stubbed(:well, plate: create(:plate), map: create(:map, description: 'A1')) }

      it 'returns the position as a hash' do
        expect(resource.position).to eq('name' => 'A1')
      end
    end
  end
end
