# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/user_resource'

RSpec.describe Api::V2::UserResource, type: :resource do
  let(:resource_model) { create :user }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :uuid
    is_expected.to have_attribute :login
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:uuid)
    is_expected.to_not have_updatable_field(:login)
    is_expected.to filter(:user_code)
  end
end
