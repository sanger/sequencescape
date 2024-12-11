# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/submission_resource'

RSpec.describe Api::V2::SubmissionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:sequencing_requests) { build_stubbed_list(:sequencing_request, 3) }
  let(:resource_model) { build_stubbed(:submission, sequencing_requests:) }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :used_tags
    expect(resource).to have_attribute :state
    expect(resource).to have_attribute :created_at
    expect(resource).to have_attribute :updated_at
    expect(resource).to have_attribute :lanes_of_sequencing
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:state)
    expect(resource).not_to have_updatable_field(:created_at)
    expect(resource).not_to have_updatable_field(:updated_at)
    expect(resource).not_to have_updatable_field :used_tags
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
  describe '#lanes_of_sequencing' do
    it 'returns the number of sequencing requests in the submission' do
      expect(resource.lanes_of_sequencing).to eq 3
    end
  end
end
