# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag2Layout do
  subject { create(:tag2_layout, plate:, tag:) }

  let(:plate) { create(:plate_with_untagged_wells, :with_submissions, sample_count: 2) }
  let(:tag) { create(:tag) }
  let!(:tag2_layout_template) { create(:tag2_layout_template, tag:) }

  it 'applies its tag to every well of the plate' do
    expect(subject.plate.wells).to be_present
    subject.plate.wells.each do |well|
      expect(well.aliquots).to be_present
      well.aliquots.each { |aliquot| expect(aliquot.reload.tag2).to eq(tag) }
    end
  end

  it 'sets a library on every well of the plate' do
    expect(subject.plate.wells).to be_present
    subject.plate.wells.each do |well|
      expect(well.aliquots).to be_present
      well.aliquots.each { |aliquot| expect(aliquot.reload.library_id).to eq(well.id) }
    end
  end
end
