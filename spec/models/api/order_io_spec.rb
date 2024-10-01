# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::OrderIO do
  subject do
    create(
      :order,
      user: user,
      template_name: 'Cool template',
      study: study,
      project: project,
      comments: 'Good',
      request_options: {
        read_length: '200',
        library_type: 'Standard',
        fragment_size_required_from: '10',
        fragment_size_required_to: '20',
        bait_library_name: 'EG',
        sequencing_type: 'MagBead',
        insert_size: 12
      }
    )
  end

  let(:user) { create(:user) }
  let(:study) { create(:study) }
  let(:project) { create(:project) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'created_by' => user.login,
      'template_name' => 'Cool template',
      'study_name' => study.name,
      'study_uuid' => study.uuid,
      'project_name' => project.name,
      'project_uuid' => project.uuid,
      'comments' => 'Good',
      'request_options' => {
        'read_length' => 200,
        'library_type' => 'Standard',
        'fragment_size_required' => {
          'from' => 10,
          'to' => 20
        },
        'bait_library' => 'EG',
        'sequencing_type' => 'MagBead',
        'insert_size' => 12
      }
    }
  end

  it_behaves_like('an IO object')
end
