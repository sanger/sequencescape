# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

RSpec.describe TagGroup::FormObject, type: :model do
  context 'when valid oligos are entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3) }

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end
  end

  context 'when an invalid oligo is entered with valid oligos' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    it 'the model is invalid' do
      tag_group_form_object.oligos_text = 'ACGTACGT INVALID ACTGCATG'
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when only invalid oligos are entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    it 'the model is invalid' do
      tag_group_form_object.oligos_text = 'INVALID1 INVALID2 INVALID3'
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when a duplicate oligo is entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    it 'the model is invalid' do
      tag_group_form_object.oligos_text = 'ACGTACGT ACTGCATG ACTGCATG'
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when oligos are separated by multiple spaces' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    before(:each) do
      tag_group_form_object.oligos_text = ' ACGTACGT    ACTGCATG  ACTGGGCC   '
    end

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end

    it 'the model creates the correct number of tags' do
      tag_group_form_object.save
      expect(tag_group_form_object.tag_group.tags.count).to eq(3)
    end
  end

  context 'when no oligos are entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    it 'the model is invalid' do
      tag_group_form_object.oligos_text = '        '
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when many oligos are entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 384) }

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end
  end

  context 'when no name is entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3, name: nil) }

    it 'the model is invalid' do
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when entered name is only spaces' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3, name: '    ') }

    it 'the model is invalid' do
      expect(tag_group_form_object.valid?).to be_falsey
    end
  end

  context 'when a valid model is saved' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3) }

    before(:each) do
      tag_group_form_object.save
    end

    it 'creates a valid tag group' do
      expect(tag_group_form_object.tag_group.valid?).to be_truthy
    end
  end

  context 'when the oligos are entered with commas separating them' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    before(:each) do
      tag_group_form_object.oligos_text = 'ACCTTGGA,GGTTACAC,TAATCGCA'
    end

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end

    it 'the correct numbers of tags are generated' do
      tag_group_form_object.save
      expect(tag_group_form_object.tag_group.tags.count).to eq(3)
    end
  end

  context 'when the oligos are entered with commas and spaces separating them' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    before(:each) do
      tag_group_form_object.oligos_text = 'ACCTTGGA, GGTTACAC,  TAATCGCA'
    end

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end

    it 'the correct numbers of tags are generated' do
      tag_group_form_object.save
      expect(tag_group_form_object.tag_group.tags.count).to eq(3)
    end
  end

  context 'when the oligos are entered as lowercase' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    before(:each) do
      tag_group_form_object.oligos_text = 'accttgga'
    end

    it 'the model is valid' do
      expect(tag_group_form_object.valid?).to be_truthy
    end

    it 'the tags are saved as uppercase' do
      tag_group_form_object.save
      expect(tag_group_form_object.tag_group.tags.first.oligo).to eq('ACCTTGGA')
    end
  end
end
