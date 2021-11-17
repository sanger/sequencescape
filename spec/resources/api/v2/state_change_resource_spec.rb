# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/state_change_resource'

RSpec.describe Api::V2::StateChangeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :state_change }

  shared_examples 'a state change resource' do
    # Test attributes
    it { is_expected.to have_attribute :previous_state }
    it { is_expected.to have_attribute :target_state }
    it { is_expected.to have_attribute :created_at }
    it { is_expected.to have_attribute :updated_at }

    # Read only attributes (almost certainly id, uuid)

    # Updatable fields
    # eg. it { is_expected.to have_updatable_field(:state) }

    # Filters
    # eg. it { is_expected.to filter(:order_type) }

    # Associations
    it { is_expected.to have_one(:labware) }

    # Custom method tests
    # Add tests for any custom methods you've added.
  end

  it_behaves_like 'a state change resource'
end
