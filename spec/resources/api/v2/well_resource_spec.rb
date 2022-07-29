# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/well_resource'

RSpec.describe Api::V2::WellResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :well, plate: plate, map: position }

  shared_examples 'a well resource' do
    # Test attributes
    it { is_expected.to have_attribute :uuid }
    it { is_expected.to have_attribute :name }
    it { is_expected.to have_attribute :state }
    it { is_expected.to have_attribute(:position) }

    # Read only attributes (almost certainly id, uuid)
    it { is_expected.not_to have_updatable_field(:id) }
    it { is_expected.not_to have_updatable_field(:uuid) }
    it { is_expected.not_to have_updatable_field(:name) }
    it { is_expected.not_to have_updatable_field(:position) }

    # Updatable fields
    it { is_expected.to have_updatable_field(:pcr_cycles) }
    it { is_expected.to have_updatable_field(:submit_for_sequencing) }
    it { is_expected.to have_updatable_field(:sub_pool) }
    it { is_expected.to have_updatable_field(:coverage) }
    it { is_expected.to have_updatable_field(:diluent_volume) }

    # Filters
    # eg. it { is_expected.to filter(:order_type) }

    # Associations
    it { is_expected.to have_many(:samples).with_class_name('Sample') }
    it { is_expected.to have_many(:projects).with_class_name('Project') }
    it { is_expected.to have_many(:studies).with_class_name('Study') }
    it { is_expected.to have_many(:qc_results).with_class_name('QcResult') }
    it { is_expected.to have_many(:requests_as_source).with_class_name('Request') }
    it { is_expected.to have_many(:requests_as_target).with_class_name('Request') }
    it { is_expected.to have_many(:aliquots).with_class_name('Aliquot') }
    it { is_expected.to have_many(:downstream_assets) }
    it { is_expected.to have_many(:transfer_requests_as_source).with_class_name('TransferRequest') }
    it { is_expected.to have_many(:transfer_requests_as_target).with_class_name('TransferRequest') }

    # Custom method tests
    # Add tests for any custom methods you've added.

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
