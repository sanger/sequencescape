# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/study_metadata_resource'

RSpec.describe Api::V2::StudyMetadataResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { create(:study_metadata) }

  # Mutability
  it { expect(described_class.mutable?).to be(false) }

  # Model Name
  it { is_expected.to have_model_name 'Study::Metadata' }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:faculty_sponsor).with_class_name('FacultySponsor') }
end
