# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/aliquot_resource'

RSpec.describe Api::V2::AliquotResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:aliquot) }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :tag_oligo
    expect(resource).to have_attribute :tag2_oligo

    # Not sure about these two. They become really tricky to
    # handle if we re-factor tags. But v. useful to users
    # Possibly store as some kind of metadata with other useful details
    # (eg. tag set, lot number?)
    expect(resource).to have_attribute :tag_index
    expect(resource).to have_attribute :tag2_index
    expect(resource).to have_attribute :suboptimal
    expect(resource).to have_attribute :library_type
    expect(resource).to have_attribute :insert_size_to
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:tag_oligo)
    expect(resource).not_to have_updatable_field(:tag2_oligo)
    expect(resource).not_to have_updatable_field(:suboptimal)
    expect(resource).not_to have_updatable_field(:library_type)
    expect(resource).not_to have_updatable_field(:insert_size_to)
    expect(resource).to have_a_writable_has_one(:library).with_class_name('Receptacle')
    expect(resource).to have_a_writable_has_one(:project).with_class_name('Project')
    expect(resource).to have_a_writable_has_one(:receptacle).with_class_name('Receptacle')
    expect(resource).to have_a_writable_has_one(:request).with_class_name('Request')
    expect(resource).to have_a_writable_has_one(:sample).with_class_name('Sample')
    expect(resource).to have_a_writable_has_one(:study).with_class_name('Study')
    expect(resource).to have_a_writable_has_one(:tag).with_class_name('Tag')
    expect(resource).to have_a_writable_has_one(:tag2).with_class_name('Tag')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
