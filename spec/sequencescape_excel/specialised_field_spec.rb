# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::SpecialisedField, type: :model, sample_manifest_excel: true, sample_manifest: true do
  class Thing
    include SequencescapeExcel::SpecialisedField::Base
  end

  class MyPerfectClass
    include SequencescapeExcel::SpecialisedField::Base
    include SequencescapeExcel::SpecialisedField::ValueRequired
  end

  let(:map) { create(:map) }
  let(:asset) { create(:untagged_well, map: map) }
  let(:sample_manifest_asset) { create :sample_manifest_asset, asset: asset, sanger_sample_id: sample.sanger_sample_id }
  let!(:library_type) { create(:library_type) }
  let!(:reference_genome) { create(:reference_genome, name: 'new one') }
  let(:aliquot) { sample_manifest_asset.asset.aliquots.first }
  let(:sample) { create :sample_with_sanger_sample_id }

  describe 'Thing' do
    it 'can be initialized with a value and a sample_manifest_asset' do
      thing = Thing.new(value: 'value', sample_manifest_asset: sample_manifest_asset)
      expect(thing.value).to eq 'value'
      expect(thing.sample).to eq sample
    end

    it 'knows if value is present' do
      thing = Thing.new(sample_manifest_asset: sample_manifest_asset)
      expect(thing).not_to be_value_present
      thing.value = 'value'
      expect(thing).to be_value_present
    end
  end

  describe 'value required' do
    it 'will produce the correct error message' do
      my_perfect_class = MyPerfectClass.new(value: nil)
      my_perfect_class.valid?
      expect(my_perfect_class.errors.full_messages).to include('My perfect class can\'t be blank')
    end
  end

  describe 'Library Type' do
    it 'will not be valid without a persisted library type' do
      expect(SequencescapeExcel::SpecialisedField::LibraryType.new(value: library_type.name, sample_manifest_asset: sample_manifest_asset)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::LibraryType.new(value: 'A new library type', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
    end

    it 'will add the the value to the aliquot' do
      specialised_field = SequencescapeExcel::SpecialisedField::LibraryType.new(value: library_type.name)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.library_type).to eq(library_type.name)
    end
  end

  describe 'Reference Genome' do
    it 'is valid, if a value was not provided' do
      expect(SequencescapeExcel::SpecialisedField::ReferenceGenome.new(sample_manifest_asset: sample_manifest_asset)).to be_valid
    end

    it 'will not be valid without a persisted reference genome if a value is provided' do
      expect(SequencescapeExcel::SpecialisedField::ReferenceGenome.new(value: reference_genome.name, sample_manifest_asset: sample_manifest_asset)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::ReferenceGenome.new(value: 'A new reference genome', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
    end

    it 'will add reference genome to sample_metadata' do
      specialised_field = SequencescapeExcel::SpecialisedField::ReferenceGenome.new(value: reference_genome.name, sample_manifest_asset: sample_manifest_asset)
      specialised_field.update
      expect(sample_manifest_asset.sample.sample_metadata.reference_genome).to eq(reference_genome)
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::InsertSizeFrom' do
    it 'value must be a valid number greater than 0' do
      expect(SequencescapeExcel::SpecialisedField::InsertSizeFrom.new(value: 'zero')).not_to be_valid
      expect(SequencescapeExcel::SpecialisedField::InsertSizeFrom.new(value: -1)).not_to be_valid
    end

    it 'will add the value to the aliquot' do
      specialised_field = SequencescapeExcel::SpecialisedField::InsertSizeFrom.new(value: 100)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.insert_size_from).to eq(100)
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::InsertSizeTo' do
    it 'value must be a valid number greater than 0' do
      expect(SequencescapeExcel::SpecialisedField::InsertSizeTo.new(value: 'zero', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      expect(SequencescapeExcel::SpecialisedField::InsertSizeTo.new(value: -1, sample_manifest_asset: sample_manifest_asset)).not_to be_valid
    end

    it 'will add the value to the aliquot' do
      specialised_field = SequencescapeExcel::SpecialisedField::InsertSizeTo.new(value: 100)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.insert_size_to).to eq(100)
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::SangerPlateId' do
    let!(:sample_1) { create(:sample_with_well) }
    let!(:sample_1_plate) { sample_1.wells.first.plate }
    let(:sample_manifest_asset_1) { create :sample_manifest_asset, asset: sample_1.primary_receptacle }

    it 'will be valid if the value matches the sanger human barcode' do
      expect(SequencescapeExcel::SpecialisedField::SangerPlateId.new(value: sample_1_plate.human_barcode, sample_manifest_asset: sample_manifest_asset_1)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::SangerPlateId.new(value: '1234', sample_manifest_asset: sample_manifest_asset_1)).not_to be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample_2) { create(:sample_with_well) }
      let(:sample_manifest_asset_2) { create :sample_manifest_asset, asset: sample_2.primary_receptacle }

      it 'will be valid if the value matches an unused cgap foreign barcode' do
        expect(SequencescapeExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC001', sample_manifest_asset: sample_manifest_asset_1)).to be_valid
      end

      it 'will not be valid if the value matches an already used cgap foreign barcode' do
        sample_1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(SequencescapeExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC011', sample_manifest_asset: sample_manifest_asset_2)).not_to be_valid
      end

      it 'will be valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample_1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = SequencescapeExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC022', sample_manifest_asset: sample_manifest_asset_1)
        expect(field).to be_valid
        field.update(aliquot: sample_1.wells.first.aliquots.first)
        expect(sample_1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample_1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).not_to be_nil
      end
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::SangerSampleId' do
    it 'will set the sanger sample id from the sample' do
      expect(SequencescapeExcel::SpecialisedField::SangerSampleId.new(value: '1234', sample_manifest_asset: sample_manifest_asset).value).to eq('1234')
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::SangerTubeId' do
    let!(:sample_1) { create(:sample) }
    let!(:sample_1_tube) { create(:sample_tube_with_sanger_sample_id, sample: sample_1) }

    let(:manifest_asset) { create :sample_manifest_asset, asset: sample_1_tube }

    it 'will be valid if the value matches the sanger human barcode' do
      expect(SequencescapeExcel::SpecialisedField::SangerTubeId.new(value: sample_1_tube.human_barcode, sample_manifest_asset: manifest_asset)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::SangerTubeId.new(value: '1234', sample_manifest_asset: manifest_asset)).not_to be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample_2) { create(:sample) }
      let!(:sample_2_tube) { create(:sample_tube_with_sanger_sample_id, sample: sample_2) }
      let(:manifest_asset2) { create :sample_manifest_asset, asset: sample_2_tube }

      it 'will be valid if the value matches an unused cgap foreign barcode' do
        expect(SequencescapeExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC001', sample_manifest_asset: manifest_asset)).to be_valid
      end

      it 'will not be valid if the value matches an already used cgap foreign barcode' do
        sample_1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(SequencescapeExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC011', sample_manifest_asset: manifest_asset2)).not_to be_valid
      end

      it 'will be valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample_1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = SequencescapeExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC022', sample_manifest_asset: manifest_asset)
        expect(field).to be_valid
        field.update(aliquot: sample_1_tube.aliquots.first)
        sample_1_tube.reload
        expect(sample_1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample_1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).not_to be_nil
      end
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::Well' do
    it 'will not be valid unless the value matches the well description' do
      expect(SequencescapeExcel::SpecialisedField::Well.new(value: 'well', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      expect(SequencescapeExcel::SpecialisedField::Well.new(value: sample_manifest_asset.asset.map_description, sample_manifest_asset: sample_manifest_asset)).to be_valid
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber' do
    it 'will not be valid if the value is different to the sample accession number' do
      expect(SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: '', sample_manifest_asset: sample_manifest_asset)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: 'EB123', sample_manifest_asset: sample_manifest_asset)).to be_valid
      sample_manifest_asset.sample.sample_metadata.sample_ebi_accession_number = 'EB123'
      expect(SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: '', sample_manifest_asset: sample_manifest_asset)).to be_valid
      expect(SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: 'EB1234', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      expect(SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: 'EB123', sample_manifest_asset: sample_manifest_asset)).to be_valid
    end
  end

  describe 'SampleManifestExcel::Tags' do
    let!(:tag_group) { create(:tag_group) }
    let(:oligo) { 'AA' }

    describe 'SequencescapeExcel::SpecialisedField::I7' do
      let(:i7) { SequencescapeExcel::SpecialisedField::I7.new(value: oligo, sample_manifest_asset: sample_manifest_asset) }

      it 'will not be valid if the tag does not contain A, C, G or T' do
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'ACGT', sample_manifest_asset: sample_manifest_asset)).to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'acgt', sample_manifest_asset: sample_manifest_asset)).to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'acgt', sample_manifest_asset: sample_manifest_asset)).to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'aatc', sample_manifest_asset: sample_manifest_asset)).to be_valid

        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'ACGT ACGT', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'BCGT', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: '-CGT', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
        expect(SequencescapeExcel::SpecialisedField::I7.new(value: 'xCGT', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      it 'will add the value' do
        expect(i7.value).to eq(oligo)
      end

      it 'will update the aliquot and create the tag if oligo is present' do
        i7.update(aliquot: aliquot, tag_group: tag_group)
        tag = tag_group.tags.find_by(oligo: oligo)
        expect(tag).to be_present
        expect(tag.oligo).to eq(oligo)
        expect(tag.map_id).to eq(1)
        aliquot.save
        expect(aliquot.tag).to eq(tag)
      end

      it 'if oligo is not present aliquot tag should be -1' do
        i7 = SequencescapeExcel::SpecialisedField::I7.new(value: nil, sample_manifest_asset: sample_manifest_asset)
        i7.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag_id).to eq(-1)
      end

      it 'will find the tag if it already exists' do
        tag = tag_group.tags.create(oligo: oligo, map_id: 10)
        i7.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag).to eq(tag)
      end
    end

    describe 'SequencescapeExcel::SpecialisedField::I5' do
      let(:i5) { SequencescapeExcel::SpecialisedField::I5.new(value: oligo, sample_manifest_asset: sample_manifest_asset) }

      it 'will not be valid if the tag does not contain A, C, G or T' do
        expect(SequencescapeExcel::SpecialisedField::I5.new(value: 'ACGT', sample_manifest_asset: sample_manifest_asset)).to be_valid
        expect(SequencescapeExcel::SpecialisedField::I5.new(value: 'BCGT', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      it 'will add the value' do
        expect(i5.value).to eq(oligo)
      end

      it 'will update the aliquot' do
        i5.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag2).to eq(tag_group.tags.find_by(oligo: oligo))
      end
    end
  end

  describe 'SequencescapeExcel::SpecialisedField::TagGroups' do
    let!(:tag_group) { create(:tag_group_with_tags) }
    let!(:tag2_group) { create(:tag_group_with_tags) }
    let(:tag_group_name) { tag_group.name }
    let(:tag2_group_name) { tag2_group.name }
    let(:tag_index) { tag_group.tags[0].map_id }
    let(:tag2_index) { tag2_group.tags[0].map_id }

    describe 'tag group' do
      it 'will add the value' do
        sf_tag_group = SequencescapeExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag_group.value).to eq(tag_group_name)
      end

      it 'will be valid with an existing tag group name' do
        expect(SequencescapeExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)).to be_valid
      end

      it 'will not be valid without an existing tag group name' do
        expect(SequencescapeExcel::SpecialisedField::TagGroup.new(value: 'unknown', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      it 'responds to update method but does nothing to tag on aliquot' do
        sf_tag_group = SequencescapeExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag_group.update(aliquot: aliquot, tag_group: nil)).to eq(nil)
        aliquot.save
        expect(aliquot.tag).to eq(nil)
      end
    end

    describe 'SequencescapeExcel::SpecialisedField::TagIndex' do
      it 'will add the value' do
        sf_tag_index = SequencescapeExcel::SpecialisedField::TagIndex.new(value: tag_index, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag_index.value).to eq(tag_index)
      end

      it 'will not have a valid tag index when unlinked from a tag group' do
        expect(SequencescapeExcel::SpecialisedField::TagIndex.new(value: tag_index, sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      describe 'linking' do
        let!(:sf_tag_group) { SequencescapeExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset) }
        let!(:sf_tag_index) { SequencescapeExcel::SpecialisedField::TagIndex.new(value: tag_index, sample_manifest_asset: sample_manifest_asset) }

        before do
          sf_tag_index.sf_tag_group = sf_tag_group
        end

        it 'will have a valid tag index when linked to a tag group' do
          expect(sf_tag_index).to be_valid
        end

        it 'will not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag_index2 = SequencescapeExcel::SpecialisedField::TagIndex.new(value: 10, sample_manifest_asset: sample_manifest_asset)
          sf_tag_index2.sf_tag_group = sf_tag_group
          expect(sf_tag_index2).not_to be_valid
        end

        it 'will update the aliquot with tag if its oligo is present' do
          sf_tag_index.update(aliquot: aliquot, tag_group: nil)
          tag = tag_group.tags.find_by(map_id: tag_index)
          expect(tag).to be_present
          expect(tag.oligo).to eq(tag_group.tags[0].oligo)
          expect(tag.map_id).to eq(1)
          aliquot.save
          expect(aliquot.tag).to eq(tag)
        end

        it 'if tag oligo is not present aliquot tag should be -1' do
          tag = tag_group.tags.find_by(map_id: tag_index)
          expect(tag).to be_present
          tag.oligo = nil
          tag.save
          expect(tag.oligo).to eq(nil)
          sf_tag_index.update(aliquot: aliquot, tag_group: nil)
          aliquot.save
          expect(aliquot.tag_id).to eq(-1)
        end
      end
    end

    describe 'SequencescapeExcel::SpecialisedField::Tag2Group' do
      it 'will add the value' do
        sf_tag2_group = SequencescapeExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag2_group.value).to eq(tag2_group_name)
      end

      it 'will be valid with an existing tag2 group name' do
        expect(SequencescapeExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample_manifest_asset: sample_manifest_asset)).to be_valid
      end

      it 'will not be valid without an existing tag2 group name' do
        expect(SequencescapeExcel::SpecialisedField::Tag2Group.new(value: 'unknown', sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      it 'responds to update method but does nothing to tag2 on aliquot' do
        sf_tag2_group = SequencescapeExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag2_group.update(aliquot: aliquot, tag_group: nil)).to eq(nil)
        aliquot.save
        expect(aliquot.tag2).to eq(nil)
      end
    end

    describe 'SequencescapeExcel::SpecialisedField::Tag2Index' do
      it 'will add the value' do
        sf_tag2_index = SequencescapeExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample_manifest_asset: sample_manifest_asset)
        expect(sf_tag2_index.value).to eq(tag2_index)
      end

      it 'will not have a valid tag index when unlinked from a tag group' do
        expect(SequencescapeExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample_manifest_asset: sample_manifest_asset)).not_to be_valid
      end

      describe 'linking' do
        let!(:sf_tag2_group) { SequencescapeExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample_manifest_asset: sample_manifest_asset) }
        let!(:sf_tag2_index) { SequencescapeExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample_manifest_asset: sample_manifest_asset) }

        before do
          sf_tag2_index.sf_tag2_group = sf_tag2_group
        end

        it 'will have a valid tag index when linked to a tag group' do
          expect(sf_tag2_index).to be_valid
        end

        it 'will not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag2_index2 = SequencescapeExcel::SpecialisedField::Tag2Index.new(value: 10, sample_manifest_asset: sample_manifest_asset)
          sf_tag2_index2.sf_tag2_group = sf_tag2_group
          expect(sf_tag2_index2).not_to be_valid
        end

        it 'will update the aliquot with tag2 if its oligo is present' do
          sf_tag2_index.update(aliquot: aliquot, tag_group: nil)
          tag2 = tag2_group.tags.find_by(map_id: tag2_index)
          expect(tag2).to be_present
          expect(tag2.oligo).to eq(tag2_group.tags[0].oligo)
          expect(tag2.map_id).to eq(1)
          aliquot.save
          expect(aliquot.tag2).to eq(tag2)
        end

        it 'if tag2 oligo is not present aliquot tag should be -1' do
          tag2 = tag2_group.tags.find_by(map_id: tag2_index)
          expect(tag2).to be_present
          tag2.oligo = nil
          tag2.save
          expect(tag2.oligo).to eq(nil)
          sf_tag2_index.update(aliquot: aliquot, tag_group: nil)
          aliquot.save
          expect(aliquot.tag2_id).to eq(-1)
        end
      end
    end
  end
end
