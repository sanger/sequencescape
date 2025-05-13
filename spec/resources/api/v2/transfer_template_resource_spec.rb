# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_template_resource'

RSpec.describe Api::V2::TransferTemplateResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:transfer_template) }

  # Model Name
  it { is_expected.to have_model_name 'TransferTemplate' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :name }
  it { is_expected.to have_readonly_attribute :uuid }

  # Filters
  it { is_expected.to filter(:uuid) }
end
