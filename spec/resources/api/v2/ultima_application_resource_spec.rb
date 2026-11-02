# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/ultima_application_resource'

RSpec.describe Api::V2::UltimaApplicationResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:ultima_application) }

  # Model Name
  it { is_expected.to have_model_name 'UltimaApplication' }

  # Attributes
  it { is_expected.to have_readonly_attribute :name }
  it { is_expected.to have_readonly_attribute :description }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:uga_primer).with_class_name('UltimaPrimer') }
  it { is_expected.to have_a_readonly_has_one(:ugb_primer).with_class_name('UltimaPrimer') }

  # Filters
  it { is_expected.to filter(:name) }

  describe 'primers' do
    it 'returns the UGA primer of the application' do
      expect(resource.uga_primer._model).to eq(resource_model.uga_primer)
    end

    it 'returns the UGB primer of the application' do
      expect(resource.ugb_primer._model).to eq(resource_model.ugb_primer)
    end
  end
end
