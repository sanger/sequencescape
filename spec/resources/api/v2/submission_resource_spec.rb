# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/submission_resource'

RSpec.describe Api::V2::SubmissionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:sequencing_requests) { build_stubbed_list(:sequencing_request, 3) }
  let(:resource_model) { build_stubbed(:submission, sequencing_requests:) }

  # Model Name
  it { is_expected.to have_model_name 'Submission' }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :used_tags
    expect(resource).to have_attribute :state
    expect(resource).to have_attribute :created_at
    expect(resource).to have_attribute :updated_at
    expect(resource).to have_attribute :lanes_of_sequencing
    expect(resource).to have_attribute :multiplexed?
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:state)
    expect(resource).not_to have_updatable_field(:created_at)
    expect(resource).not_to have_updatable_field(:updated_at)
    expect(resource).not_to have_updatable_field :used_tags
  end

  # Attributes
  it { is_expected.to have_writeonly_attribute :and_submit }
  it { is_expected.to have_readonly_attribute :created_at }
  it { is_expected.to have_write_once_attribute :lanes_of_sequencing }
  it { is_expected.to have_write_once_attribute :name }
  it { is_expected.to have_writeonly_attribute :order_uuids }
  it { is_expected.to have_readonly_attribute :state }
  it { is_expected.to have_readonly_attribute :updated_at }
  it { is_expected.to have_write_once_attribute :used_tags }
  it { is_expected.to have_writeonly_attribute :user_uuid }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
  it { is_expected.to have_a_writable_has_many(:orders).with_class_name('Order') }

  # Filters
  it { is_expected.to filter(:uuid) }

  # Custom methods
  describe '#self.submit!' do
    context 'when the and_submit attribute is true' do
      before { resource.send(:and_submit=, true) }

      it 'submits the submission' do
        allow(resource_model).to receive(:built!)

        resource.submit!

        expect(resource_model).to have_received(:built!)
      end
    end

    context 'when the and_submit attribute is false' do
      before { resource.send(:and_submit=, false) }

      it 'does not submit the submission' do
        allow(resource_model).to receive(:built!)

        resource.submit!

        expect(resource_model).not_to have_received(:built!)
      end
    end

    context 'when the and_submit attribute is nil' do
      before { resource.send(:and_submit=, nil) }

      it 'does not submit the submission' do
        allow(resource_model).to receive(:built!)

        resource.submit!

        expect(resource_model).not_to have_received(:built!)
      end
    end
  end

  describe '#multiplexed?' do
    context 'when the submission is multiplexed' do
      before { allow(resource_model).to receive(:multiplexed?).and_return(true) }

      it 'returns whether the submission is multiplexed' do
        expect(resource.multiplexed?).to be true
      end
    end

    context 'when the submission is not multiplexed' do
      before { allow(resource_model).to receive(:multiplexed?).and_return(false) }

      it 'returns whether the submission is multiplexed' do
        expect(resource.multiplexed?).to be false
      end
    end
  end
end
