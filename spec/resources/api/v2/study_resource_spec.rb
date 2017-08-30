require 'rails_helper'
require './app/resources/api/v2/study_resource'

RSpec.describe Api::V2::StudyResource, type: :resource do
  let(:study) { create :study }
  subject { described_class.new(study, {}) }

  it { is_expected.to have_attribute :name }
  it { is_expected.to have_attribute :uuid }
end
