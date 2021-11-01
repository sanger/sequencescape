# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_resource'

RSpec.describe Api::V2::TubeRackResource, type: :resource do
  subject(:tube_rack) { described_class.new(resource_model, {}) }

  let(:resource_model) { create :tube_rack }

  it { is_expected.to have_attribute :uuid }
  it { is_expected.to have_attribute :labware_barcode }
  it { is_expected.to have_attribute :size }

  it { is_expected.not_to have_updatable_field(:uuid) }
  it { is_expected.not_to have_updatable_field(:labware_barcode) }

  it { is_expected.to have_updatable_field(:size) }
  it { is_expected.to have_updatable_field(:tube_locations) }

  it { is_expected.to filter(:barcode) }
  it { is_expected.to filter(:uuid) }
  it { is_expected.to filter(:purpose_name) }
  it { is_expected.to filter(:purpose_id) }

  it { is_expected.to have_one(:purpose).with_class_name('Purpose') }
  it { is_expected.to have_many(:racked_tubes).with_class_name('RackedTube') }

  describe 'tube_locations=' do
    let(:a1_tube) { create :tube }
    let(:b1_tube) { create :tube }
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
      let(:new_locations) { { } }

      it 'doesn\'t create any associations' do
        tube_rack.tube_locations = new_locations
        expect(tube_rack.racked_tubes).to be_empty
      end
    end

    context 'when given an invalid tube uuid' do
      before do
        new_locations[:B1][:uuid] = 'invalid_uuid'
      end

      it 'raises with a descriptive message' do
        expect { tube_rack.tube_locations = new_locations }.to(
          raise_error("No tube found for UUID 'invalid_uuid'")
        )
      end
    end
  end
end
