# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagGroup::FormObject do
  context 'when validating the oligos entered by the user' do
    let(:tag_group_form_object) { build(:tag_group_form_object) }

    context 'when valid oligos are entered' do
      it 'the model is valid' do
        tag_group_form_object.oligos_text = 'ACGTACGT ATTGGCCT ACTGCATG'
        expect(tag_group_form_object).to be_valid
      end
    end

    context 'when an invalid oligo is entered with valid oligos' do
      it 'the model is invalid' do
        tag_group_form_object.oligos_text = 'ACGTACGT INVALID ACTGCATG'
        expect(tag_group_form_object).not_to be_valid
      end
    end

    context 'when only invalid oligos are entered' do
      it 'the model is invalid' do
        tag_group_form_object.oligos_text = 'INVALID1 INVALID2 INVALID3'
        expect(tag_group_form_object).not_to be_valid
      end
    end

    context 'when a duplicate oligo is entered' do
      it 'the model is invalid' do
        tag_group_form_object.oligos_text = 'ACGTACGT ACTGCATG ACTGCATG'
        expect(tag_group_form_object).not_to be_valid
      end
    end

    context 'when oligos are separated by multiple spaces' do
      before { tag_group_form_object.oligos_text = ' ACGTACGT    ACTGCATG  ACTGGGCC   ' }

      it 'the model is valid' do
        expect(tag_group_form_object).to be_valid
      end

      it 'the model creates the correct number of tags' do
        tag_group_form_object.save
        expect(tag_group_form_object.tag_group.tags.count).to eq(3)
      end
    end

    context 'when no oligos are entered' do
      it 'the model is invalid' do
        tag_group_form_object.oligos_text = '        '
        expect(tag_group_form_object).not_to be_valid
      end
    end

    context 'when many oligos are entered' do
      let(:tag_group_form_object_many) { build(:tag_group_form_object, oligos_count: 384) }

      it 'the model is valid' do
        expect(tag_group_form_object_many).to be_valid
      end
    end

    context 'when the oligos are entered with commas separating them' do
      before { tag_group_form_object.oligos_text = 'ACCTTGGA,GGTTACAC,TAATCGCA' }

      it 'the model is valid' do
        expect(tag_group_form_object).to be_valid
      end

      it 'the correct numbers of tags are generated' do
        tag_group_form_object.save
        expect(tag_group_form_object.tag_group.tags.count).to eq(3)
      end
    end

    context 'when the oligos are entered with commas and spaces separating them' do
      before { tag_group_form_object.oligos_text = 'ACCTTGGA, GGTTACAC,  TAATCGCA' }

      it 'the model is valid' do
        expect(tag_group_form_object).to be_valid
      end

      it 'the correct numbers of tags are generated' do
        tag_group_form_object.save
        expect(tag_group_form_object.tag_group.tags.count).to eq(3)
      end
    end

    context 'when the oligos are entered as lowercase' do
      before { tag_group_form_object.oligos_text = 'accttgga' }

      it 'the model is valid' do
        expect(tag_group_form_object).to be_valid
      end

      it 'the tags are saved as uppercase' do
        tag_group_form_object.save
        expect(tag_group_form_object.tag_group.tags.first.oligo).to eq('ACCTTGGA')
      end
    end
  end

  context 'when no name is entered' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3, name: nil) }

    it 'the model is invalid' do
      expect(tag_group_form_object).not_to be_valid
    end
  end

  context 'when entered name is only spaces' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3, name: '    ') }

    it 'the model is invalid' do
      expect(tag_group_form_object).not_to be_valid
    end
  end

  context 'when a valid model is saved' do
    let(:tag_group_form_object) { build(:tag_group_form_object, oligos_count: 3) }

    it 'creates a valid tag group' do
      tag_group_form_object.save
      expect(tag_group_form_object.tag_group).to be_valid
    end
  end
end
