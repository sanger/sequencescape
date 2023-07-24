# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::BatchIO do
  subject { create :batch, user: user, assignee: user2, pipeline: pipeline }

  let(:user) { create :user }
  let(:user2) { create :user }
  let(:pipeline) { create :pipeline }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'created_by' => user.login,
      'assigned_to' => user2.login,
      'pipeline_name' => pipeline.name,
      'pipeline_uuid' => pipeline.uuid,
      'pipeline_internal_id' => pipeline.id,
      'state' => subject.state,
      'qc_state' => subject.qc_state,
      'production_state' => subject.production_state
    }
  end

  it_behaves_like('an IO object')
end
