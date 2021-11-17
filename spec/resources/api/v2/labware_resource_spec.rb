# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/labware_resource'

RSpec.describe Api::V2::LabwareResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :labware }

  shared_examples 'a labware resource' do
    # Test attributes
    it { is_expected.to have_attribute :uuid }
    it { is_expected.to have_attribute :created_at }

    # Read only attributes (almost certainly id, uuid)

    # Updatable fields
    # eg. it { is_expected.to have_updatable_field(:state) }

    # Filters
    # eg. it { is_expected.to filter(:order_type) }
    it { is_expected.to filter(:barcode) }
    it { is_expected.to filter(:uuid) }
    it { is_expected.to filter(:purpose_name) }
    it { is_expected.to filter(:purpose_id) }
    it { is_expected.to filter(:without_children) }
    it { is_expected.to filter(:created_at_gt) }

    # Associations
    it { is_expected.to have_one(:purpose).with_class_name('Purpose') }
    it { is_expected.to have_many(:ancestors) }
    it { is_expected.to have_many(:state_changes) }

    # Custom method tests
    # Add tests for any custom methods you've added.
  end

  it_behaves_like 'a labware resource'
end
