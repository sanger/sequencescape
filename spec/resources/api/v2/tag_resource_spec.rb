# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_resource'

RSpec.describe Api::V2::TagResource, type: :resource do
  subject(:tag_resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag) }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(tag_resource).to have_attribute :oligo
    expect(tag_resource).to have_attribute :map_id

    expect(tag_resource).to have_one(:tag_group).with_class_name('TagGroup')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
