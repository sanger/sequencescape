# frozen_string_literal: true

require 'rails_helper'
require './spec/resources/api/v2/shared_examples/receptacle'
require './app/resources/api/v2/receptacle_resource'

RSpec.describe Api::V2::ReceptacleResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:receptacle) }

  # Model Name
  it { is_expected.to have_model_name 'Receptacle' }

  # Behaviours
  it_behaves_like 'a receptacle resource'
end
