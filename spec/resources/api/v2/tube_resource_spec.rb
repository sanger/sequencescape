# frozen_string_literal: true

require 'rails_helper'
require './spec/resources/api/v2/shared_examples/labware'
require './app/resources/api/v2/tube_resource'

RSpec.describe Api::V2::TubeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tube) }

  # Model Name
  it { is_expected.to have_model_name('Tube') }

  # Attributes
  it { is_expected.to have_readonly_attribute(:sibling_tubes) }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:aliquots).with_class_name('Aliquot') }
  it { is_expected.to have_a_readonly_has_one(:receptacle).with_class_name('Receptacle') }
  it { is_expected.to have_a_readonly_has_many(:transfer_requests_as_target).with_class_name('TransferRequest') }
  it { is_expected.to have_a_readonly_has_many(:racked_tube).with_class_name('RackedTube') }

  # Behaviours
  it_behaves_like 'a labware resource'
end
