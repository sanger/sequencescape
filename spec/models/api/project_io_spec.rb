# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ProjectIO, type: :model do
  subject { create :project }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id
    }
  end

  it_behaves_like('an IO object')
end
