# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/request_resource'

RSpec.describe Api::V2::RequestResource, type: :resource do
  let(:resource_model) { create :request }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :uuid
    is_expected.to have_attribute :state
    is_expected.to have_attribute :priority
    is_expected.to have_attribute :role
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:uuid)
    is_expected.to_not have_updatable_field(:state)
    is_expected.to_not have_updatable_field(:role)
    is_expected.to have_one(:submission).with_class_name('Submission')
    is_expected.to have_one(:order).with_class_name('Order')
    is_expected.to have_one(:request_type).with_class_name('RequestType')
    is_expected.to have_one(:primer_panel).with_class_name('PrimerPanel')
  end

  let(:expected_metadata) { { 'customer_accepts_responsibility' => false } }

  # Custom method tests
  # Add tests for any custom methods you've added.
  it 'renders relevant metadata' do
    expect(subject.options).to eq(expected_metadata)
  end

  context 'isc request' do
    let(:resource_model) { create :isc_request, bait_library: bait_library }
    let(:bait_library) { create :bait_library }
    let(:expected_metadata) do
      {
        'library_type' => 'Standard',
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'bait_library' => bait_library.name,
        'pre_capture_plex_level' => 8
      }
    end

    # Custom method tests
    # Add tests for any custom methods you've added.
    it 'renders relevant metadata' do
      expect(subject.options).to eq(expected_metadata)
    end
  end
end
