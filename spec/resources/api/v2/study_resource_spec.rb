# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/study_resource'

RSpec.describe Api::V2::StudyResource, type: :resource do
  subject { described_class.new(study, {}) }

  let(:study) { create :study }

  it 'works', :aggregate_failures do
    expect(subject).to have_attribute :name
    expect(subject).to have_attribute :uuid
  end
end
