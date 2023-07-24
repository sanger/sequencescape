# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/aliquot_resource'

RSpec.describe Api::V2::AliquotResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :aliquot }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to have_attribute :tag_oligo
    expect(subject).to have_attribute :tag2_oligo

    # Not sure about these two. They become really tricky to
    # handle if we re-factor tags. But v. useful to users
    # Possibly store as some kind of metadata with other useful details
    # (eg. tag set, lot number?)
    expect(subject).to have_attribute :tag_index
    expect(subject).to have_attribute :tag2_index
    expect(subject).to have_attribute :suboptimal
    expect(subject).to have_attribute :library_type
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:tag_oligo)
    expect(subject).not_to have_updatable_field(:tag2_oligo)
    expect(subject).not_to have_updatable_field(:suboptimal)
    expect(subject).not_to have_updatable_field(:library_type)
    expect(subject).to have_one(:sample).with_class_name('Sample')
    expect(subject).to have_one(:tag).with_class_name('Tag')
    expect(subject).to have_one(:tag2).with_class_name('Tag')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
