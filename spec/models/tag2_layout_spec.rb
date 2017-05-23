require 'rails_helper'

RSpec.describe Tag2Layout, type: :model do
  let(:plate) { create :plate_with_untagged_wells, sample_count: 2 }
  let(:tag) { create :tag }

  subject { create :tag2_layout, plate: plate, tag: tag }

  it 'applies its tag to every well of the plate' do
    subject.plate.wells.each do |well|
      expect(well.aliquots).to be_present
      well.aliquots.each do |aliquot|
        expect(aliquot.reload.tag2).to eq(tag)
      end
    end
  end

  it 'sets a library on every well of the plate' do
    subject.plate.wells.each do |well|
      expect(well.aliquots).to be_present
      well.aliquots.each do |aliquot|
        expect(aliquot.reload.library_id).to eq(well.id)
      end
    end
  end
end
