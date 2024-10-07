# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ReferenceGenomeIo do
  subject { create(:reference_genome) }

  let(:expected_json) { { 'uuid' => subject.uuid, 'internal_id' => subject.id } }

  it_behaves_like('an IO object')
end
