# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/submission_pool_resource'

RSpec.describe Api::V2::SubmissionPoolResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:submission_pool) }

  # Attributes
  it { is_expected.to have_readonly_attribute :plates_in_submission }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:tag_layout_templates).with_class_name('TagLayoutTemplate') }
end
