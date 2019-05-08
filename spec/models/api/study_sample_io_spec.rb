# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::StudySampleIO, type: :model do
  subject { create :study_sample, study: study, sample: sample }

  let(:study) { create :study }
  let(:sample) { create :sample }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'sample_internal_id' => sample.id,
      'sample_uuid' => sample.uuid,
      'study_internal_id' => study.id,
      'study_uuid' => study.uuid
    }
  end

  it_behaves_like('an IO object')
end
