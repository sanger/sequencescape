# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::SubmissionIo do
  subject { create(:submission, user:) }

  let(:user) { create(:user) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'created_by' => user.login,
      'state' => subject.state,
      'message' => subject.message
    }
  end

  it_behaves_like('an IO object')
end
