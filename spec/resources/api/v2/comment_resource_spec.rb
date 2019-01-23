# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/comment_resource'

RSpec.describe Api::V2::CommentResource, type: :resource do
  let(:resource_model) { create :comment }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :title
    is_expected.to have_attribute :description
    is_expected.to_not have_updatable_field(:id)
    is_expected.to have_one(:user).with_class_name('User')
    is_expected.to have_one(:commentable)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
