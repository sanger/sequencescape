require 'rails_helper'

RSpec.describe SampleManifestExcel::SpecialisedField, type: :model, sample_manifest_excel: true do

  let!(:sample) { create(:sample_with_well) }
  let!(:library_type) { create(:library_type) }

  describe 'donor ID' do

    it 'will set the sanger sample ID from the sample' do
      expect(SampleManifestExcel::SpecialisedField::DonorId.new(sample).value).to eq(sample.sanger_sample_id)
    end

  end

  describe 'donor Id 2' do

    it 'will set the sanger sample ID from the sample' do
      expect(SampleManifestExcel::SpecialisedField::DonorId2.new(sample).value).to eq(sample.sanger_sample_id)
    end

  end

  describe 'Library Type' do

    it 'will not be valid without a persisted library type' do
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new(library_type.name)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new('A new library type')).to_not be_valid
    end
  end

  describe 'Insert Size From' do

    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new("zero")).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(-1)).to_not be_valid
    end
  end

  describe 'Insert Size To' do

    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new("zero")).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new(-1)).to_not be_valid
    end
  end

  describe 'Sanger Plate Id' do

    it 'will set the sanger plate id from the sample' do
      expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(sample).value).to eq(sample.wells.first.plate.sanger_human_barcode)
    end
  end

  describe 'Sanger Sample Id' do

    it 'will set the sanger sample id from the sample' do
      expect(SampleManifestExcel::SpecialisedField::SangerSampleId.new(sample).value).to eq(sample.sanger_sample_id)
    end
  end

  describe 'Sanger Tube Id' do

    it 'will set the sanger tube id from the sample' do
      expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(sample).value).to eq(sample.assets.first.sanger_human_barcode)
    end
  end

  describe 'Well' do

    it 'will set the well description' do
      expect(SampleManifestExcel::SpecialisedField::Well.new(sample).value).to eq(sample.wells.first.map.description)
    end
  end

  describe 'tags' do

    let!(:tag_group) { create(:tag_group) }
    let(:oligo) { 'AA'}
    let(:aliquot) { sample.aliquots.first }

    describe 'tag oligo' do

      let(:tag_oligo) { SampleManifestExcel::SpecialisedField::TagOligo.new(oligo)}

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

      let(:tag2_oligo) { SampleManifestExcel::SpecialisedField::Tag2Oligo.new(oligo)}

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
