require 'rails_helper'
require './app/resources/api/v2/work_order_resource'

RSpec.describe Api::V2::WorkOrderResource, type: :resource do
  shared_examples_for 'a work order resource' do
    subject { described_class.new(request, {}) }

    it { is_expected.to have_attribute :uuid }
    it { is_expected.to have_attribute :order_type }
    it { is_expected.to have_attribute :state }
    it { is_expected.to have_attribute :at_risk }
    it { is_expected.to have_attribute :options }

    it { is_expected.to_not have_updatable_field(:uuid) }
    it { is_expected.to_not have_updatable_field(:order_type) }

    it { is_expected.to have_updatable_field(:state) }
    it { is_expected.to have_updatable_field(:at_risk) }
    it { is_expected.to have_updatable_field(:options) }

    it { is_expected.to filter(:order_type) }
    it { is_expected.to filter(:state) }

    it { is_expected.to have_many(:samples).with_class_name('Sample') }
    it { is_expected.to have_one(:source_receptacle) }
    it { is_expected.to have_one(:study).with_class_name('Study') }
    it { is_expected.to have_one(:project).with_class_name('Project') }

    it 'renders relevant metadata' do
      expect(subject.options).to eq(expected_metadata)
    end
  end

  context 'a basic request' do
    let(:request) { create :customer_request }
    let(:expected_metadata) { { 'read_length' => 76 } }
    it_behaves_like 'a work order resource'
  end

  context 'a sequencing request' do
    let(:request) { create :sequencing_request }
    let(:expected_metadata) { { 'fragment_size_required_to' => '21', 'fragment_size_required_from' => '1', 'read_length' => 76 } }
    it_behaves_like 'a work order resource'
  end
end
