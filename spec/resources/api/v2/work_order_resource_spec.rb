# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/work_order_resource'

RSpec.describe Api::V2::WorkOrderResource, type: :resource do
  subject(:resource) { described_class.new(work_order, {}) }

  let(:work_order) { create(:work_order, example_request:, requests:) }
  let(:example_request) { requests.first }
  let(:requests) { create_list(:customer_request, 1) }

  # Model Name
  it { is_expected.to have_model_name('WorkOrder') }

  # Attributes
  it { is_expected.to have_readwrite_attribute :at_risk }
  it { is_expected.to have_readonly_attribute :options }
  it { is_expected.to have_write_once_attribute :order_type }
  it { is_expected.to have_write_once_attribute :quantity }
  it { is_expected.to have_readwrite_attribute :state }

  # Relationships
  it { is_expected.to have_many(:samples).with_class_name('Sample') }
  it { is_expected.to have_one(:source_receptacle) }
  it { is_expected.to have_one(:study).with_class_name('Study') }
  it { is_expected.to have_one(:project).with_class_name('Project') }

  # Filters
  it { is_expected.to filter(:order_type) }
  it { is_expected.to filter(:state) }

  # Field Methods
  describe '#quantity' do
    subject(:quantity) { resource.quantity }

    context 'with a single request' do
      it { is_expected.to eq(number: 1, unit_of_measurement: 'flowcells') }
    end

    context 'with multiple requests' do
      let(:requests) { create_list(:customer_request, 3) }

      it { is_expected.to eq(number: 3, unit_of_measurement: 'flowcells') }
    end
  end

  describe '#study_id' do
    subject(:study_id) { resource.study_id }

    context 'with an example request with study ID 42' do
      let(:example_request) { create(:customer_request, initial_study_id: 42) }

      it { is_expected.to eq(42) }
    end
  end

  describe '#project_id' do
    subject(:project_id) { resource.project_id }

    context 'with an example request with project ID 42' do
      let(:example_request) { create(:customer_request, initial_project_id: 42) }

      it { is_expected.to eq(42) }
    end
  end

  describe '#source_receptacle_id' do
    subject(:source_receptacle_id) { resource.source_receptacle_id }

    context 'with an example request with asset ID 42' do
      let(:example_request) { create(:customer_request, asset_id: 42) }

      it { is_expected.to eq(42) }
    end
  end

  describe '#order_type' do
    subject(:order_type) { resource.order_type }

    context 'with a work order type named "example"' do
      let(:work_order) { create(:work_order, work_order_type: create(:work_order_type, name: 'example')) }

      it { is_expected.to eq('example') }
    end
  end

  describe '#options' do
    subject(:options) { resource.options }

    context 'with a customer request' do
      it { is_expected.to eq('read_length' => 76) }
    end

    context 'with a sequencing request' do
      let(:requests) { create_list(:sequencing_request, 1) }

      it do
        is_expected.to eq(
          'fragment_size_required_from' => '1',
          'fragment_size_required_to' => '21',
          'read_length' => 76
        )
      end
    end
  end
end
