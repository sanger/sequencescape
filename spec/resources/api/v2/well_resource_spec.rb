require 'rails_helper'
require './app/resources/api/v2/well_resource'

RSpec.describe Api::V2::WellResource, type: :resource do
  let(:resource_model) { create :well, plate: plate, map: position }
  subject(:resource) { described_class.new(resource_model, {}) }

  shared_examples 'a well resource' do
    # Test attributes
    it { is_expected.to have_attribute :uuid }
    it { is_expected.to have_attribute :name }
    it { is_expected.to have_attribute :state }

    # Read only attributes (almost certainly id, uuid)
    it { is_expected.to_not have_updatable_field(:id) }
    it { is_expected.to_not have_updatable_field(:uuid) }
    it { is_expected.to_not have_updatable_field(:name) }
    it { is_expected.to_not have_updatable_field(:position) }
    it { is_expected.to_not have_updatable_field(:labware_barcode) }

    # Updatable fields
    # eg. it { is_expected.to have_updatable_field(:state) }

    # Filters
    # eg. it { is_expected.to filter(:order_type) }

    # Associations
    it { is_expected.to have_many(:samples).with_class_name('Sample') }
    it { is_expected.to have_many(:projects).with_class_name('Project') }
    it { is_expected.to have_many(:studies).with_class_name('Study') }
    it { is_expected.to have_many(:qc_results).with_class_name('QcResult') }

    # Custom method tests
    # Add tests for any custom methods you've added.
    describe '#labware_barcode' do
      subject { resource.labware_barcode }
      it { is_expected.to eq(expected_barcode_hash) }
    end

    describe '#position' do
      subject { resource.position }
      it { is_expected.to eq(expected_position) }
    end
  end

  context 'on a plate' do
    let(:plate) { create :plate, barcode: '11' }
    let(:position) { create :map, description: 'A1' }
    let(:expected_barcode_hash) { { 'ean13_barcode' => '1220000011748', 'human_barcode' => 'DN11J' } }
    let(:expected_position) { { 'name' => 'A1' } }
    it_behaves_like 'a well resource'
  end

  context 'off a plate' do
    let(:plate) { nil }
    let(:position) { nil }
    let(:expected_barcode_hash) { { 'ean13_barcode' => nil, 'human_barcode' => nil } }
    let(:expected_position) { { 'name' => nil } }
    it_behaves_like 'a well resource'
  end
end
