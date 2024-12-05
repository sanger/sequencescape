# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/bait_library_layout_resource'

RSpec.describe Api::V2::BaitLibraryLayoutResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:bait_library_layout) }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :layout }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:plate).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
