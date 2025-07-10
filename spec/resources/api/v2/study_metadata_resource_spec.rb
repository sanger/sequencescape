# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/study_metadata_resource'

RSpec.describe Api::V2::StudyMetadataResource, type: :resource do
  subject(:resource) { described_class.new(study_metadata, {}) }

  let(:study_metadata) { create(:study_metadata) }

  it { is_expected.to have_a_readonly_has_one(:faculty_sponsor).with_class_name('FacultySponsor') }
end
