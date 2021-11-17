# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/user_resource'

RSpec.describe Api::V2::UserResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :user }

  # Test attributes
  it 'works', :aggregate_failures do
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :login
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).not_to have_updatable_field(:login)
    expect(subject).to filter(:user_code)
  end
end
