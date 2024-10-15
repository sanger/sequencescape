# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::TagIo do
  subject { create(:tag) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'expected_sequence' => subject.oligo,
      'map_id' => subject.map_id,
      'tag_group_name' => subject.tag_group.name,
      'tag_group_uuid' => subject.tag_group.uuid,
      'tag_group_internal_id' => subject.tag_group.id
    }
  end

  it_behaves_like('an IO object')
end
