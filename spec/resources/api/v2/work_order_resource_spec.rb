# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/work_order_resource'

RSpec.describe Api::V2::WorkOrderResource, type: :resource do
  shared_examples_for 'a work order resource' do
    subject { described_class.new(work_order, {}) }

    let(:work_order) { create(:work_order, requests:).reload }

    it { is_expected.to have_attribute :order_type }
    it { is_expected.to have_attribute :state }
    it { is_expected.to have_attribute :at_risk }
    it { is_expected.to have_attribute :options }
    it { is_expected.to have_attribute :quantity }

    it { is_expected.not_to have_updatable_field(:uuid) }
    it { is_expected.not_to have_updatable_field(:order_type) }

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

    it 'renders the expected quantity' do
      expect(subject.quantity).to eq(number: number_of_requests, unit_of_measurement: 'flowcells')
    end
  end

  context 'a basic work_order' do
    let(:number_of_requests) { 1 }
    let(:requests) { create_list(:customer_request, number_of_requests) }
    let(:expected_metadata) { { 'read_length' => 76 } }

    it_behaves_like 'a work order resource'
  end

  context 'a work_order with multiple requests' do
    let(:number_of_requests) { 3 }
    let(:requests) { create_list(:customer_request, number_of_requests) }
    let(:expected_metadata) { { 'read_length' => 76 } }

    it_behaves_like 'a work order resource'
  end

  context 'a sequencing work_order' do
    let(:number_of_requests) { 1 }
    let(:requests) { [create(:sequencing_request)] }
    let(:expected_metadata) do
      { 'fragment_size_required_to' => '21', 'fragment_size_required_from' => '1', 'read_length' => 76 }
    end

    it_behaves_like 'a work order resource'
  end
end
