# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_resource'

RSpec.describe Api::V2::TagResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag) }

  # Model Name
  it { is_expected.to have_model_name('Tag') }

  # Attributes
  it { is_expected.to have_write_once_attribute :map_id }
  it { is_expected.to have_write_once_attribute :oligo }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:tag_group).with_class_name('TagGroup') }
end
