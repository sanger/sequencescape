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
end
