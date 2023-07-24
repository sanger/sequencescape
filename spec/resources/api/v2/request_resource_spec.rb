# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/request_resource'

RSpec.describe Api::V2::RequestResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :request }

  # Test attributes
  let(:expected_metadata) { { 'customer_accepts_responsibility' => false } }

  it 'works', :aggregate_failures do
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :state
    expect(subject).to have_attribute :priority
    expect(subject).to have_attribute :role
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).to have_updatable_field(:state)
    expect(subject).not_to have_updatable_field(:role)
    expect(subject).to have_one(:submission).with_class_name('Submission')
    expect(subject).to have_one(:order).with_class_name('Order')
    expect(subject).to have_one(:request_type).with_class_name('RequestType')
    expect(subject).to have_one(:primer_panel).with_class_name('PrimerPanel')
    expect(subject).to have_one(:pre_capture_pool).with_class_name('PreCapturePool')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
  it 'renders relevant metadata' do
    expect(subject.options).to eq(expected_metadata)
  end

  context 'isc request' do
    let(:resource_model) { build_stubbed :isc_request, bait_library: bait_library }
    let(:bait_library) { create :bait_library }
    let(:expected_metadata) do
      {
        'library_type' => 'Agilent Pulldown',
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
