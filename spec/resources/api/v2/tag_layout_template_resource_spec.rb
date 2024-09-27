# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_layout_template_resource'

RSpec.describe Api::V2::TagLayoutTemplateResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag_layout_template) }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :name }
  it { is_expected.to have_readonly_attribute :direction }
  it { is_expected.to have_readonly_attribute :walking_by }

  # Filters
  it { is_expected.to filter(:enabled) }

  # Relationships
  it { is_expected.to have_one(:tag_group).with_class_name('TagGroup') }
  it { is_expected.to have_one(:tag2_group).with_class_name('TagGroup') }
end
