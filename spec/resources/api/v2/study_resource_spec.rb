# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/study_resource'

RSpec.describe Api::V2::StudyResource, type: :resource do
  subject(:resource) { described_class.new(study, {}) }

  let(:study) { create(:study) }

  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :uuid
  end

  it { is_expected.to filter :uuid }
  it { is_expected.to filter :state }
  it { is_expected.to filter :name }
  it { is_expected.to filter :user }
end
