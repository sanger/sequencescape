# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/submission_resource'

RSpec.describe Api::V2::SubmissionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:sequencing_requests) { build_stubbed_list(:sequencing_request, 3) }
  let(:resource_model) { build_stubbed(:submission, sequencing_requests:) }

  # Model Name
  it { is_expected.to have_model_name 'Submission' }

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
end
