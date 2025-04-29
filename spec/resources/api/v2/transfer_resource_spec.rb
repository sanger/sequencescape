# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_resource'

RSpec.describe Api::V2::TransferResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:transfer_between_plates) }

  # Model Name
  it { is_expected.to have_model_name 'Transfer' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :destination_uuid }
  it { is_expected.to have_readwrite_attribute :source_uuid }
  it { is_expected.to have_writeonly_attribute :transfer_template_uuid }
  it { is_expected.to have_readonly_attribute :transfer_type }
  it { is_expected.to have_readwrite_attribute :transfers }
  it { is_expected.to have_write_once_attribute :user_uuid }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:destination).with_class_name('Labware') }
  it { is_expected.to have_a_writable_has_one(:source) }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }

  # Filters
  it { is_expected.to filter(:transfer_type) }

  # Custom methods
  describe '#self.create' do
    let(:model_type) { Transfer::BetweenPlates }
    let(:context) { { model_type: } }
    let(:transfer) { model_type.new }

    before { allow(model_type).to receive(:new).and_return(transfer) }

    it 'creates the new Transfer resource with the correct model class' do
      described_class.create(context)

      expect(model_type).to have_received(:new)
    end

    it 'creates the new resource with the new Transfer::BetweenPlates' do
      allow(described_class).to receive(:new).and_call_original

      described_class.create(context)

      expect(described_class).to have_received(:new).with(transfer, context)
    end
  end
end
