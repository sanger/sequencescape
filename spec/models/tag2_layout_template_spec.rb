# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag2LayoutTemplate, type: :model do
  subject { tag2_layout_template.create! plate: plate, tag: tag, user: user }

  let(:plate) { create :plate_with_untagged_wells, :with_submissions, sample_count: 2 }
  let(:tag) { create :tag }
  let(:user) { create :user }
  let(:tag2_layout_template) { create :tag2_layout_template, tag: tag }

  it 'applies its tag to every well of the plate' do
    expect(subject.plate.wells).to be_present
    subject
      .plate
      .wells
      .each do |well|
        expect(well.aliquots).to be_present
        well.aliquots.each { |aliquot| expect(aliquot.reload.tag2).to eq(tag) }
      end
  end

  it 'sets a library on every well of the plate' do
    expect(subject.plate.wells).to be_present
    subject
      .plate
      .wells
      .each do |well|
        expect(well.aliquots).to be_present
        well.aliquots.each { |aliquot| expect(aliquot.reload.library_id).to eq(well.id) }
      end
  end

  it 'records itself against the submissions' do
    # First double check we have submissions
    # otherwise out test is a false positive
    submissions = subject.plate.submissions.map(&:id)
    expect(Tag2Layout::TemplateSubmission.where(submission_id: submissions)).to be_present
    Tag2Layout::TemplateSubmission
      .where(submission_id: submissions)
      .each { |t2lts| expect(t2lts.tag2_layout_template).to eq(tag2_layout_template) }
  end
end
