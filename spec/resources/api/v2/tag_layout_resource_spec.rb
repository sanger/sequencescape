# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_layout_resource'

RSpec.describe Api::V2::TagLayoutResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag_layout) }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }

  it { is_expected.to have_readwrite_attribute :direction }
  it { is_expected.to have_readwrite_attribute :initial_tag }
  it { is_expected.to have_readwrite_attribute :substitutions }
  it { is_expected.to have_readwrite_attribute :tags_per_well }
  it { is_expected.to have_readwrite_attribute :walking_by }

  it { is_expected.to have_writeonly_attribute :plate_uuid }
  it { is_expected.to have_writeonly_attribute :tag_group_uuid }
  it { is_expected.to have_writeonly_attribute :tag2_group_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_one(:plate).with_class_name('Plate') }
  it { is_expected.to have_one(:tag_group).with_class_name('TagGroup') }
  it { is_expected.to have_one(:tag2_group).with_class_name('TagGroup') }
  it { is_expected.to have_one(:user).with_class_name('User') }
end
