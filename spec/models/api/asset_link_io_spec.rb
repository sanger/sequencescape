# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::AssetLinkIO, type: :model do
  let(:ancestor) { create :well }
  let(:descendant) { create :multiplexed_library_tube }
  subject { create :asset_link, ancestor: ancestor, descendant: descendant }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'ancestor_uuid' => ancestor.uuid,
      'ancestor_internal_id' => ancestor.id,
      'ancestor_type' => 'wells',
      'descendant_uuid' => descendant.uuid,
      'descendant_internal_id' => descendant.id,
      'descendant_type' => 'multiplexed_library_tubes',
      'created_at' => subject.created_at.to_s
    }
  end

  it_behaves_like('an IO object')
end
