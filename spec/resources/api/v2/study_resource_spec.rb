# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/study_resource'

RSpec.describe Api::V2::StudyResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:study) }

  # Mutability
  it { expect(described_class.mutable?).to be(false) }

  # Model Name
  it { is_expected.to have_model_name 'Study' }

  # Attributes
  # Note: The attributes are effectively read-only because the resource is immutable.
  it { is_expected.to have_readwrite_attribute :name }
  it { is_expected.to have_readwrite_attribute :uuid }

  # Relationships
  it { is_expected.to have_many(:poly_metadata).with_class_name('PolyMetadatum') }
  it { is_expected.to have_a_writable_has_one(:study_metadata).with_class_name('StudyMetadata') }

  # Filters
  it { is_expected.to filter(:name) }
  it { is_expected.to filter(:state) }
  it { is_expected.to filter(:user) }
  it { is_expected.to filter(:uuid) }
end
