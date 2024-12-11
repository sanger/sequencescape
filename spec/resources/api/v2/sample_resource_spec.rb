# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sample_resource'

RSpec.describe Api::V2::SampleResource, type: :resource do
  subject { described_class.new(sample, {}) }

  let(:sample) { create(:sample) }

  # Model Name
  it { is_expected.to have_model_name 'Sample' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :control }
  it { is_expected.to have_readwrite_attribute :control_type }
  it { is_expected.to have_readwrite_attribute :name }
  it { is_expected.to have_readwrite_attribute :sanger_sample_id }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_many(:component_samples).with_class_name('Sample') }
  it { is_expected.to have_a_writable_has_one(:sample_manifest).with_class_name('SampleManifest') }
  it { is_expected.to have_a_writable_has_one(:sample_metadata).with_class_name('SampleMetadata') }
  it { is_expected.to have_a_writable_has_many(:studies).with_class_name('Study') }

  # Filters
  it { is_expected.to filter :name }
  it { is_expected.to filter :sanger_sample_id }
  it { is_expected.to filter :uuid }
end
