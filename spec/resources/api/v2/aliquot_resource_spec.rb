# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/aliquot_resource'

RSpec.describe Api::V2::AliquotResource, type: :resource do
  let(:resource_model) { create :aliquot }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :tag_oligo
    is_expected.to have_attribute :tag2_oligo
    is_expected.to have_attribute :suboptimal
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:tag_oligo)
    is_expected.to_not have_updatable_field(:tag2_oligo)
    is_expected.to_not have_updatable_field(:suboptimal)
    is_expected.to have_one(:sample).with_class_name('Sample')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
