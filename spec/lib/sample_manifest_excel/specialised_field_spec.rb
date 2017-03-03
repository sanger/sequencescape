require 'rails_helper'

RSpec.describe SampleManifestExcel::SpecialisedField, type: :model, sample_manifest_excel: true do

  class Thing
    include SampleManifestExcel::SpecialisedField::Base
  end

  let!(:sample) { create(:sample_with_well) }
  let!(:library_type) { create(:library_type) }

  describe 'Thing' do
    it 'can be initialized with a value and a sample' do
      thing = Thing.new(value: 'value', sample: sample)
      expect(thing.value).to eq 'value'
      expect(thing.sample).to eq sample
    end
  end

  describe 'Library Type' do

    it 'will not be valid without a persisted library type' do
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new(value: library_type.name, sample:sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new(value: 'A new library type', sample: sample)).to_not be_valid
    end
  end

  describe 'Insert Size From' do

    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(value: "zero", sample: sample)).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(value: -1, sample: sample)).to_not be_valid
    end
  end

  describe 'Insert Size To' do

    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new(value: "zero", sample: sample)).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new(value: -1, sample: sample)).to_not be_valid
    end
  end

  describe 'Sanger Plate Id' do

    it 'will not be valid unless the value matches the sanger human barcode' do
      expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: sample.wells.first.plate.sanger_human_barcode, sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: '1234', sample: sample)).to_not be_valid
    end
  end

  describe 'Sanger Sample Id' do

    it 'will set the sanger sample id from the sample' do
      expect(SampleManifestExcel::SpecialisedField::SangerSampleId.new(value: '1234', sample: sample).value).to eq('1234')
    end
  end

  describe 'Sanger Tube Id' do

    it 'will not be valid unless the value matches the sanger human barcode' do
      expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: sample.assets.first.sanger_human_barcode, sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: '1234', sample: sample)).to_not be_valid
    end
  end

  describe 'Well' do

    it 'will not be valid unless the value matches the well description' do
      expect(SampleManifestExcel::SpecialisedField::Well.new(value: 'well', sample: sample)).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::Well.new(value: sample.wells.first.map.description, sample: sample)).to be_valid
    end
  end

  describe 'tags' do

    let!(:tag_group) { create(:tag_group) }
    let(:oligo) { 'AA'}
    let(:aliquot) { sample.aliquots.first }

    describe 'tag oligo' do

      let(:tag_oligo) { SampleManifestExcel::SpecialisedField::TagOligo.new(value: oligo, sample: sample)}

      it 'will add the value' do
        expect(tag_oligo.value).to eq(oligo)
      end

      it 'will update the aliquot and create the tag if oligo is present' do
        tag_oligo.update(aliquot: aliquot, tag_group: tag_group)
        tag = tag_group.tags.find_by(oligo: oligo)
        expect(tag).to be_present
        expect(tag.oligo).to eq(oligo)
        expect(tag.map_id).to eq(1)
        aliquot.reload
        expect(aliquot.tag).to eq(tag)
      end

      it 'will find the tag if it already exists' do
        tag = tag_group.tags.create(oligo: oligo, map_id: 10)
        tag_oligo.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.reload
        expect(aliquot.tag).to eq(tag)
      end

    end

    describe 'tag2 oligo' do

      let(:tag2_oligo) { SampleManifestExcel::SpecialisedField::Tag2Oligo.new(value: oligo, sample: sample)}

      it 'will add the value' do
        expect(tag2_oligo.value).to eq(oligo)
      end

      it 'will update the aliquot' do
        tag2_oligo.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.reload
        expect(aliquot.tag2).to eq(tag_group.tags.find_by(oligo: oligo))
      end

    end
  end

end
