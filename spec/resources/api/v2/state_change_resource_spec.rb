# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/state_change_resource'

RSpec.describe Api::V2::StateChangeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :state_change }

  # Attributes
  it 'has the expected read-only attributes', :aggregate_failures do
    expect(resource).to have_attribute :uuid
    expect(resource).not_to have_updatable_field :uuid

    expect(resource).to have_attribute :previous_state
    expect(resource).not_to have_updatable_field :previous_state
  end

  it 'has the expected read-write attributes', :aggregate_failures do
    expect(resource).to have_attribute :contents
    expect(resource).to have_updatable_field :contents

    expect(resource).to have_attribute :reason
    expect(resource).to have_updatable_field :reason

    expect(resource).to have_attribute :target_state
    expect(resource).to have_updatable_field :target_state
  end

  it 'has the expected write-only attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :user_uuid
    expect(resource).to have_updatable_field :user_uuid

    expect(resource).not_to have_attribute :target_uuid
    expect(resource).to have_updatable_field :target_uuid

    expect(resource).not_to have_attribute :customer_accepts_responsibility
    expect(resource).to have_updatable_field :customer_accepts_responsibility
  end

  # Relationships
  it 'has the expected relationships', :aggregate_failures do
    expect(resource).to have_one(:target).with_class_name('Labware')
    expect(resource).to have_one(:user).with_class_name('User')
  end
end
