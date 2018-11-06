# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/user_resource'

RSpec.describe Api::V2::UserResource, type: :resource do
  let(:resource_model) { create :user }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it { is_expected.to have_attribute :uuid }
  it { is_expected.to have_attribute :login }

  # Read only attributes (almost certainly id, uuid)
  it { is_expected.to_not have_updatable_field(:id) }
  it { is_expected.to_not have_updatable_field(:uuid) }
  it { is_expected.to_not have_updatable_field(:login) }

  # Filters
  it { is_expected.to filter(:user_code) }
end
