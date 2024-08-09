# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_layout_template_resource'

RSpec.describe Api::V2::TagLayoutTemplateResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :tag_layout_template }

  # Expected attributes
  it { is_expected.not_to have_attribute :id }
  it { is_expected.to have_attribute :uuid }
  it { is_expected.to have_attribute :name }
  it { is_expected.to have_attribute :direction }
  it { is_expected.to have_attribute :walking_by }

  # Read-only fields
  it { is_expected.not_to have_updatable_field :uuid }
  it { is_expected.not_to have_updatable_field :name }
  it { is_expected.not_to have_updatable_field :direction }
  it { is_expected.not_to have_updatable_field :walking_by }

  # Filters
  it { is_expected.to filter(:enabled) }

  # Associations
  it { is_expected.to have_one(:tag_group).with_class_name('TagGroup') }
  it { is_expected.to have_one(:tag2_group).with_class_name('TagGroup') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
