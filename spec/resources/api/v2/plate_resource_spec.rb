# frozen_string_literal: true

require 'rails_helper'
require './spec/resources/api/v2/shared_examples/labware'
require './app/resources/api/v2/plate_resource'

RSpec.describe Api::V2::PlateResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:plate, barcode: 'SQPD-1', well_count: 3) }

  shared_examples 'a plate resource' do
    # Attributes
    it { is_expected.to have_readonly_attribute :number_of_rows }
    it { is_expected.to have_readonly_attribute :number_of_columns }
    it { is_expected.to have_write_once_attribute :size }
    it { is_expected.to have_readonly_attribute :pooling_metadata }

    # Relationships
    it { is_expected.to have_a_readonly_has_many(:submission_pools).with_class_name('SubmissionPool') }
    it { is_expected.to have_a_readonly_has_many(:transfers_as_destination).with_class_name('Transfer') }
    it { is_expected.to have_a_write_once_has_many(:wells).with_class_name('Well') }

    # Custom method tests
    # Add tests for any custom methods you've added.
    describe '#labware_barcode' do
      subject { resource.labware_barcode }

      it { is_expected.to eq(expected_barcode_hash) }
    end
  end

  context 'on a plate' do
    let(:expected_barcode_hash) do
      { 'ean13_barcode' => nil, 'machine_barcode' => 'SQPD-1', 'human_barcode' => 'SQPD-1' }
    end

    it_behaves_like 'a labware resource'
    it_behaves_like 'a plate resource'
  end
end
