# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/order_resource'

RSpec.describe Api::V2::OrderResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:order) }

  # Model Name
  it { is_expected.to have_model_name 'Order' }

  # Attributes
  it { is_expected.to have_readonly_attribute :order_type }
  it { is_expected.to have_readonly_attribute :request_options }
  it { is_expected.to have_readonly_attribute :request_types }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:project).with_class_name('Project') }
  it { is_expected.to have_a_readonly_has_one(:study).with_class_name('Study') }
  it { is_expected.to have_a_readonly_has_one(:user).with_class_name('User') }

  # Template attributes
  it { is_expected.to have_writeonly_attribute :submission_template_uuid }
  it { is_expected.to have_writeonly_attribute :submission_template_attributes }

  # Custom methods
  describe '#self.create' do
    context 'without a template in the context' do
      let(:context) { {} }
      let(:resource) { double('OrderResource') }

      it 'returns an OrderResource created by the super class' do
        expect(described_class.superclass).to receive(:create).with(context).and_return(resource)

        expect(described_class.create(context)).to eq(resource)
      end
    end

    context 'with a template in the context' do
      let(:context) { { template:, template_attributes: } }
      let(:template) { double('SubmissionTemplate') }
      let(:template_attributes) { {} }
      let(:order) { create(:order) }

      it 'does not call create on the super class' do
        expect(described_class.superclass).not_to receive(:create).with(context)
      end

      it 'creates a new OrderResource with a new Order created by the SubmissionTemplate' do
        allow(template).to receive(:create_order!).and_return(order)
        allow(described_class).to receive(:new).and_call_original

        described_class.create(context)

        expect(described_class).to have_received(:new).with(order, context)
      end
    end
  end
end
