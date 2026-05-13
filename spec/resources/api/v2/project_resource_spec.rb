# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/project_resource'

RSpec.describe Api::V2::ProjectResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:project) }

  # Model Name
  it { is_expected.to have_model_name 'Project' }

  # Attributes
  it { is_expected.to have_attribute :name }
  it { is_expected.to have_attribute :cost_code }
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :state }

  # Read-only fields
  it { is_expected.not_to have_updatable_field :uuid }
  it { is_expected.not_to have_updatable_field :state }

  # Filters
  it { is_expected.to filter :name }
end
