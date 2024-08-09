# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/user_resource'

RSpec.describe Api::V2::UserResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :user }

  # Expected attributes
  it { is_expected.not_to have_attribute :id }
  it { is_expected.to have_attribute :uuid }
  it { is_expected.to have_attribute :login }
  it { is_expected.to have_attribute :first_name }
  it { is_expected.to have_attribute :last_name }

  # Read-only fields
  it { is_expected.not_to have_updatable_field :uuid }
  it { is_expected.not_to have_updatable_field :login }
  it { is_expected.not_to have_updatable_field :first_name }
  it { is_expected.not_to have_updatable_field :last_name }

  # Filters
  it { is_expected.to filter(:user_code) }
  it { is_expected.to filter(:uuid) }
end
