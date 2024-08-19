# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_set_resource'

RSpec.describe Api::V2::TagSetResource, type: :resource do
  subject(:tag_set) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :tag_set }

  it 'exposes attributes', :aggregate_failures do
    expect(tag_set).to have_attribute :name
    expect(tag_set).not_to have_updatable_field(:name)
  end

  it 'exposes associations', :aggregate_failures do
    expect(tag_set).to have_one(:tag_group).with_class_name('TagGroup')
    expect(tag_set).to have_one(:tag2_group).with_class_name('TagGroup')
  end
end
