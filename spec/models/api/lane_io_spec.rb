# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::LaneIo do
  subject { create :lane }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'name' => subject.name,
      'qc_state' => subject.qc_state, # WH aliases as state,
      'external_release' => subject.external_release
    }
  end

  it_behaves_like('an IO object')
end
