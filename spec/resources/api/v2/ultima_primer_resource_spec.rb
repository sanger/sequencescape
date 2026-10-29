# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/ultima_primer_resource'

RSpec.describe Api::V2::UltimaPrimerResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:ultima_primer) }

  # Model Name
  it { is_expected.to have_model_name 'UltimaPrimer' }

  # Attributes
  it { is_expected.to have_readonly_attribute :name }
end
