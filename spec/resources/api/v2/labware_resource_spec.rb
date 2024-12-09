# frozen_string_literal: true

require 'rails_helper'
require './spec/resources/api/v2/shared_examples/labware'
require './app/resources/api/v2/labware_resource'

RSpec.describe Api::V2::LabwareResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:labware) }

  it_behaves_like 'a labware resource'
end
