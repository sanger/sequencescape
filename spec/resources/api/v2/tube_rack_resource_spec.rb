# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_resource'

RSpec.describe Api::V2::TubeRackResource, type: :resource do
  subject(:tube_rack) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tube_rack) }

  # Test attributes
  it 'has attributes', :aggregate_failures do
    expect(tube_rack).to have_attribute :uuid
    expect(tube_rack).to have_attribute :size
    expect(tube_rack).to have_attribute :name
    expect(tube_rack).to have_attribute :number_of_rows
    expect(tube_rack).to have_attribute :number_of_columns
    expect(tube_rack).to have_attribute :labware_barcode
    expect(tube_rack).to have_attribute :created_at
    expect(tube_rack).to have_attribute :updated_at
    expect(tube_rack).not_to have_updatable_field(:id)
    expect(tube_rack).not_to have_updatable_field(:uuid)
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }
  it 'exposes associations', :aggregate_failures do
    expect(tube_rack).to have_many(:racked_tubes).with_class_name('RackedTube')
    expect(tube_rack).to have_one(:purpose).with_class_name('TubeRackPurpose')
    expect(tube_rack).to have_one(:comments).with_class_name('Comment')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.

  describe 'tube_locations=' do
    let(:a1_tube) { create(:tube) }
    let(:b1_tube) { create(:tube) }
    let(:new_locations) { { A1: { uuid: a1_tube.uuid }, B1: { uuid: b1_tube.uuid } } }

    it 'adds associations for the two tubes' do
      tube_rack.tube_locations = new_locations
      expect(tube_rack.racked_tubes.count).to eq(2)
      expect(tube_rack.racked_tubes[0].coordinate).to eq('A1')
      expect(tube_rack.racked_tubes[0].tube.uuid).to eq(a1_tube.uuid)
      expect(tube_rack.racked_tubes[1].coordinate).to eq('B1')
      expect(tube_rack.racked_tubes[1].tube.uuid).to eq(b1_tube.uuid)
    end

    context 'when passed an empty locations object' do
      let(:new_locations) { {} }

      it 'doesn\'t create any associations' do
        tube_rack.tube_locations = new_locations
        expect(tube_rack.racked_tubes).to be_empty
      end
    end

    context 'when given an invalid tube uuid' do
      before { new_locations[:B1][:uuid] = 'invalid_uuid' }

      it 'raises with a descriptive message' do
        expect { tube_rack.tube_locations = new_locations }.to(raise_error("No tube found for UUID 'invalid_uuid'"))
      end
    end
  end

  describe 'filters' do
    let(:purpose) { create(:tube_rack_purpose, name: 'Test Purpose') }
    let(:other_purpose) { create(:tube_rack_purpose, name: 'Other Purpose') }
    let!(:tube_rack_with_purpose) { create(:tube_rack, purpose:) }
    let!(:tube_rack_with_other_purpose) { create(:tube_rack, purpose: other_purpose) }

    describe 'purpose_name' do
      it 'filters tube racks by purpose name' do
        records = described_class.apply_filters(TubeRack.all, { purpose_name: 'Test Purpose' }, {})

        expect(records).to include(tube_rack_with_purpose)
        expect(records).not_to include(tube_rack_with_other_purpose)
      end

      it 'returns no records if the purpose name does not match' do
        records = described_class.apply_filters(TubeRack.all, { purpose_name: 'Nonexistent Purpose' }, {})
        expect(records).to be_empty
      end
    end
  end
end
