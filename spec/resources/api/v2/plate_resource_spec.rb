require 'rails_helper'
require './app/resources/api/v2/plate_resource'

RSpec.describe Api::V2::PlateResource, type: :resource do
  let(:resource_model) { create :plate, barcode: 11, well_count: 3 }
  subject(:resource) { described_class.new(resource_model, {}) }

  shared_examples 'a plate resource' do
    # Test attributes
    it { is_expected.to have_attribute :uuid }
    it { is_expected.to have_attribute :name }
    # it { is_expected.to have_attribute :labware_barcodes }
    # it { is_expected.to have_attribute :position }

    # Read only attributes (almost certainly id, uuid)
    it { is_expected.to_not have_updatable_field(:id) }
    it { is_expected.to_not have_updatable_field(:uuid) }
    it { is_expected.to_not have_updatable_field(:name) }
    it { is_expected.to_not have_updatable_field(:labware_barcode) }

    # Updatable fields
    # eg. it { is_expected.to have_updatable_field(:state) }

    # Filters
    # eg. it { is_expected.to filter(:order_type) }

    # Associations
    it { is_expected.to have_many(:wells).with_class_name('Well') }
    it { is_expected.to have_many(:projects).with_class_name('Project') }
    it { is_expected.to have_many(:studies).with_class_name('Study') }

    # Custom method tests
    # Add tests for any custom methods you've added.
    describe '#labware_barcode' do
      subject { resource.labware_barcode }
      it { is_expected.to eq(expected_barcode_hash) }
    end
  end

  context 'on a plate' do
    let(:expected_barcode_hash) { { 'ean13_barcode' => '1220000011748', 'sanger_human_barcode' => 'DN11J' } }
    it_behaves_like 'a plate resource'
  end
end
