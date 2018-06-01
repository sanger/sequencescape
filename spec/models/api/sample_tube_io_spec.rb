# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::SampleTubeIO, type: :model do
  subject { create :sample_tube }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id
    }
  end

  it_behaves_like('an IO object')
end
