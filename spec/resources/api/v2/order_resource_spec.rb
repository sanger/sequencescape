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

      it 'returns an OrderResource created by the super class' do
        allow(described_class.superclass).to receive(:create).with(context).and_return(resource)

        expect(described_class.create(context)).to eq(resource)
      end
    end

    context 'with a template in the context' do
      let(:context) { { template:, template_attributes: } }
      let(:template) { instance_double(SubmissionTemplate) }
      let(:template_attributes) { {} }

      before { allow(template).to receive(:create_order!).with(template_attributes).and_return(resource_model) }

      it 'does not call create on the super class' do
        allow(described_class.superclass).to receive(:create)

        described_class.create(context)

        expect(described_class.superclass).not_to have_received(:create)
      end

      it 'creates a new OrderResource with a new Order created by the SubmissionTemplate' do
        allow(described_class).to receive(:new)

        described_class.create(context)

        expect(described_class).to have_received(:new).with(resource_model, context)
      end
    end
  end
end
