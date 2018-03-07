# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

RSpec.describe TagGroup, type: :model do
  context 'when valid oligos are entered' do
    let(:tag_group) { build(:tag_group, oligos_text: 'ACGTACGT AACCTTGG') }
    # let(:expected_hash) { { '1' => 'ACGTACGT', '2' => 'AACCTTGG' } }
    # let(:expected_text) { 'ACGTACGT AACCTTGG' }

    it 'the model is valid' do
      expect(tag_group.valid?).to be_truthy
    end
  end

  context 'when invalid oligos are entered' do
    let(:tag_group) { build(:tag_group, oligos_text: 'ACGTACGT AABBCCDD') }
    
    it 'the model is invalid' do
      expect(tag_group.valid?).to be_falsey
    end
  end

  context 'when no oligos are entered' do
    let(:tag_group) { build(:tag_group, oligos_text: '   ') }
    
    it 'the model is invalid' do
      expect(tag_group.valid?).to be_falsey
    end
  end
end
