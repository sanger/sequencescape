# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_resource'

RSpec.describe Api::V2::TubeRackResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tube_rack) }

  # Model Name
  it { is_expected.to have_model_name('TubeRack') }

  # Attributes
  it { is_expected.to have_readonly_attribute(:created_at) }
  it { is_expected.to have_write_once_attribute(:labware_barcode) }
  it { is_expected.to have_write_once_attribute(:name) }
  it { is_expected.to have_write_once_attribute(:number_of_columns) }
  it { is_expected.to have_write_once_attribute(:number_of_rows) }
  it { is_expected.to have_write_once_attribute(:size) }
  it { is_expected.to have_writeonly_attribute(:tube_locations) }
  it { is_expected.to have_readonly_attribute(:updated_at) }
  it { is_expected.to have_readonly_attribute(:uuid) }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:comments).with_class_name('Comment') }
  it { is_expected.to have_a_writable_has_one(:purpose).with_class_name('TubeRackPurpose') }
  it { is_expected.to have_a_writable_has_many(:racked_tubes).with_class_name('RackedTube') }

  # Filters
  it { is_expected.to filter(:barcode) }
  it { is_expected.to filter(:purpose_id) }
  it { is_expected.to filter(:purpose_name) }
  it { is_expected.to filter(:uuid) }

  # Associations
  it { is_expected.to have_many(:racked_tubes).with_class_name('RackedTube') }
  it { is_expected.to have_one(:purpose).with_class_name('TubeRackPurpose') }
  it { is_expected.to have_one(:comments).with_class_name('Comment') }

  # Field Methods
  describe '#tube_locations=' do
    let(:a1_tube) { create(:tube) }
    let(:b1_tube) { create(:tube) }
    let(:new_locations) { { A1: { uuid: a1_tube.uuid }, B1: { uuid: b1_tube.uuid } } }

    it 'adds associations for the two tubes' do
      resource.tube_locations = new_locations
      expect(resource.racked_tubes.count).to eq(2)
      expect(resource.racked_tubes[0].coordinate).to eq('A1')
      expect(resource.racked_tubes[0].tube.uuid).to eq(a1_tube.uuid)
      expect(resource.racked_tubes[1].coordinate).to eq('B1')
      expect(resource.racked_tubes[1].tube.uuid).to eq(b1_tube.uuid)
    end

    context 'when passed an empty locations object' do
      let(:new_locations) { {} }

      it "doesn't create any associations" do
        resource.tube_locations = new_locations
        expect(resource.racked_tubes).to be_empty
      end
    end

    context 'when given an invalid tube uuid' do
      before { new_locations[:B1][:uuid] = 'invalid_uuid' }

      it 'raises with a descriptive message' do
        expect { resource.tube_locations = new_locations }.to(raise_error("No tube found for UUID 'invalid_uuid'"))
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

  describe '#labware_barcode' do
    let(:resource_model) { build_stubbed(:tube_rack, barcodes: [barcode]) }
    let(:barcode) { create(:sanger_ean13) }

    it 'returns a hash of the barcode attributes' do
      expect(resource.labware_barcode).to eq(
        'ean13_barcode' => barcode.ean13_barcode,
        'machine_barcode' => barcode.machine_barcode,
        'human_barcode' => barcode.human_barcode
      )
    end
  end
end
