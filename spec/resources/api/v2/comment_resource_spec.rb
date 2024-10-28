# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/comment_resource'

RSpec.describe Api::V2::CommentResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:comment) }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to have_attribute :title
    expect(subject).to have_attribute :description
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).to have_a_writable_has_one(:user).with_class_name('User')
    expect(subject).to have_a_writable_has_one(:commentable)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
