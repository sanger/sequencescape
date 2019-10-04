# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

# Note: These tests JUST check the factory characteristic of layout
# templates. The actual layout of tags is carried out by the tag layouts themselves,
# and is tested there.
describe TagLayoutTemplate do
  let(:template) do
    build :tag_layout_template,
          direction_algorithm: direction_algorithm,
          walking_algorithm: walking_algorithm,
          tag2_group: tag2_group,
          tags: ['AAA']
  end

  describe '#create!' do
    subject { template.create!(plate: plate, user: user) }

    let(:user) { build :user }

    let(:plate) { create :plate }
    let(:tag2_group) { nil }
    let(:enforce_uniqueness) { nil }

    context 'by plate in columns' do
      let(:direction_algorithm) { 'TagLayout::InColumns' }
      let(:walking_algorithm) { 'TagLayout::WalkWellsOfPlate' }
      let(:plate) { create :plate, :with_submissions, well_count: 1 }

      it { is_expected.to be_a TagLayout }

      it 'passes in the correct properties' do
        expect(subject.plate).to eq(plate)
        expect(subject.direction).to eq('column')
        expect(subject.walking_by).to eq('wells of plate')
        expect(tag2_group).to eq(tag2_group)
      end

      it 'records itself against the submissions' do
        # First double check we have submissions
        # otherwise out test is a false positive
        subject
        submissions = plate.submissions.map(&:id)
        expect(TagLayout::TemplateSubmission.where(submission_id: submissions)).to be_present
        TagLayout::TemplateSubmission.where(submission_id: submissions).each do |tlts|
          expect(tlts.tag_layout_template).to eq(template)
          expect(tlts.enforce_uniqueness).to eq(enforce_uniqueness)
        end
      end

      context 'with a tag2 group' do
        let(:enforce_uniqueness) { true }
        let(:tag2_group) { create :tag_group_with_tags }

        it { is_expected.to be_a TagLayout }

        it 'passes in the correct properties' do
          expect(subject.plate).to eq(plate)
          expect(subject.tag2_group).to eq(tag2_group)
        end

        it 'records itself against the submissions' do
          # First double check we have submissions
          # otherwise out test is a false positive
          subject
          submissions = plate.submissions.map(&:id)
          expect(TagLayout::TemplateSubmission.where(submission_id: submissions)).to be_present
          TagLayout::TemplateSubmission.where(submission_id: submissions).each do |tlts|
            expect(tlts.tag_layout_template).to eq(template)
            expect(tlts.enforce_uniqueness).to eq(enforce_uniqueness)
          end
        end
      end
    end

    context 'by pool in rows' do
      let(:direction_algorithm) { 'TagLayout::InRows' }
      let(:walking_algorithm) { 'TagLayout::WalkWellsByPools' }

      it { is_expected.to be_a TagLayout }

      it 'passes in the correct properties' do
        expect(subject.plate).to eq(plate)
        expect(subject.direction).to eq('row')
        expect(subject.walking_by).to eq('wells in pools')
      end
    end
  end
end
