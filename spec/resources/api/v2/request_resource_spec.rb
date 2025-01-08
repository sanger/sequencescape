# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/request_resource'

RSpec.describe Api::V2::RequestResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:request) }

  # Model Name
  it { is_expected.to have_model_name 'Request' }

  # Attributes
  it { is_expected.to have_readonly_attribute :library_type }
  it { is_expected.to have_readonly_attribute :options }
  it { is_expected.to have_write_once_attribute :priority }
  it { is_expected.to have_write_once_attribute :role }
  it { is_expected.to have_readwrite_attribute :state }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:order).with_class_name('Order') }
  it { is_expected.to have_a_writable_has_many(:poly_metadata).with_class_name('PolyMetadatum') }
  it { is_expected.to have_a_readonly_has_one(:pre_capture_pool).with_class_name('PreCapturePool') }
  it { is_expected.to have_a_readonly_has_one(:primer_panel).with_class_name('PrimerPanel') }
  it { is_expected.to have_a_writable_has_many(:request_metadata).with_class_name('RequestMetadata') }
  it { is_expected.to have_a_writable_has_one(:request_type).with_class_name('RequestType') }
  it { is_expected.to have_a_writable_has_one(:submission).with_class_name('Submission') }

  # Field Methods
  describe '#options' do
    context 'default request' do
      it 'renders the correct options' do
        expect(resource.options).to eq('customer_accepts_responsibility' => false)
      end
    end

    context 'isc request' do
      let(:resource_model) { build_stubbed(:isc_request, bait_library:) }
      let(:bait_library) { create(:bait_library) }

      it 'renders the correct options' do
        expect(resource.options).to eq(
          'library_type' => 'Agilent Pulldown',
          'fragment_size_required_to' => '400',
          'fragment_size_required_from' => '100',
          'bait_library' => bait_library.name,
          'pre_capture_plex_level' => 8
        )
      end
    end
  end

  describe '#primer_panel_id' do
    context 'when the request metadata contains a primer panel id' do
      let(:resource_model) { build_stubbed(:request, request_metadata:) }
      let(:request_metadata) { build_stubbed(:request_metadata, primer_panel_id: 42) }

      it 'returns the primer panel id' do
        expect(resource.primer_panel_id).to eq(42)
      end
    end

    context 'when the request metadata does not contain a primer panel id' do
      it 'returns nil' do
        expect(resource.primer_panel_id).to be_nil
      end
    end
  end

  describe '#pre_capture_pool_id' do
    context 'when the pooled request contains a pre-capture pool' do
      let(:resource_model) { build_stubbed(:request, pooled_request:) }
      let(:pooled_request) { build_stubbed(:pooled_request, pre_capture_pool:) }
      let(:pre_capture_pool) { build_stubbed(:pre_capture_pool, id: 42) }

      it 'returns the primer panel id' do
        expect(resource.pre_capture_pool_id).to eq(42)
      end
    end

    context 'when there is no pooled request' do
      it 'returns nil' do
        expect(resource.pre_capture_pool_id).to be_nil
      end
    end
  end

  describe '#library_type' do
    context 'when the request has a library type' do
      let(:resource_model) { build_stubbed(:isc_request) }

      it 'returns the library type' do
        expect(resource.library_type).to eq('Agilent Pulldown')
      end
    end

    context 'when the request does not have a library type' do
      it 'returns nil' do
        expect(resource.library_type).to be_nil
      end
    end
  end
end
