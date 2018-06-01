# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::TagIO, type: :model do
  subject { create :tag }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id
    }
  end

  it_behaves_like('an IO object')
end
