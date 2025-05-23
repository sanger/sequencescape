# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/work_completion_resource'

RSpec.describe Api::V2::WorkCompletionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:work_completion) }

  # Model Name
  it { is_expected.to have_model_name 'WorkCompletion' }

  # Attributes
  it { is_expected.to have_writeonly_attribute :submission_uuids }
  it { is_expected.to have_writeonly_attribute :target_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_a_write_once_has_many(:submissions).with_class_name('Submission') }
  it { is_expected.to have_a_write_once_has_one(:target).with_class_name('Labware') }
  it { is_expected.to have_a_write_once_has_one(:user).with_class_name('User') }
end
