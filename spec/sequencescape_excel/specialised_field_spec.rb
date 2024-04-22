# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::SpecialisedField, :sample_manifest, :sample_manifest_excel, type: :model do
  let(:map) { create(:map) }
  let(:asset) { create(:untagged_well, map:) }
  let(:asset2) { create(:untagged_well, map:) }
  let(:sample_manifest) { create(:sample_manifest) }
  let(:sample_manifest_asset) do
    create(:sample_manifest_asset,
           asset:,
           sanger_sample_id: sample.sanger_sample_id,
           sample_manifest:)
  end
  let(:sample_manifest_asset2) do
    create(:sample_manifest_asset,
           asset: asset2,
           sanger_sample_id: sample2.sanger_sample_id,
           sample_manifest:)
  end
  let!(:library_type) { create(:library_type) }
  let!(:reference_genome) { create(:reference_genome, name: 'new one') }
  let(:aliquot) { sample_manifest_asset.asset.aliquots.first }
  let(:sample) { create(:sample_with_sanger_sample_id) }
  let(:sample2) { create(:sample_with_sanger_sample_id) }

  describe SequencescapeExcel::SpecialisedField::Base do
    # We use an anonymous class as classes created in specs have global scope.
    # @see https://rubocop-rspec.readthedocs.io/en/latest/cops_rspec/#rspecleakyconstantdeclaration
    let(:class_with_base) { Class.new { include SequencescapeExcel::SpecialisedField::Base } }

    it 'can be initialized with a value and a sample_manifest_asset' do
      thing = class_with_base.new(value: 'value', sample_manifest_asset:)
      expect(thing.value).to eq 'value'
      expect(thing.sample).to eq sample
    end

    it 'knows if value is present' do
      thing = class_with_base.new(sample_manifest_asset:)
      expect(thing).not_to be_value_present
      thing.value = 'value'
      expect(thing).to be_value_present
    end
  end

  describe SequencescapeExcel::SpecialisedField::ValueRequired do
    # We use an anonymous class as classes created in specs have global scope.
    # @see https://rubocop-rspec.readthedocs.io/en/latest/cops_rspec/#rspecleakyconstantdeclaration
    let(:class_with_base_and_value_required) do
      Class.new do
        def self.name
          'MyPerfectClass'
        end

        include SequencescapeExcel::SpecialisedField::Base
        include SequencescapeExcel::SpecialisedField::ValueRequired
      end
    end

    it 'produces the correct error message' do
      my_perfect_class = class_with_base_and_value_required.new(value: nil)
      my_perfect_class.valid?
      expect(my_perfect_class.errors.full_messages.join).to include('My perfect class can\'t be blank')
    end
  end

  describe SequencescapeExcel::SpecialisedField::LibraryType do
    it 'does not be valid without a persisted library type' do
      expect(described_class.new(value: library_type.name, sample_manifest_asset:)).to be_valid
      expect(
        described_class.new(value: 'A new library type', sample_manifest_asset:)
      ).not_to be_valid
    end

    it 'adds the the value to the aliquot' do
      specialised_field = described_class.new(value: library_type.name, sample_manifest_asset:)
      specialised_field.update(aliquot:)
      expect(aliquot.library_type).to eq(library_type.name)
    end

    context 'with multiple aliquots' do
      let(:asset) { create(:tagged_well, map:, aliquot_count: 2) }

      it 'adds the the value to all aliquots' do
        specialised_field = described_class.new(value: library_type.name, sample_manifest_asset:)
        specialised_field.update(aliquot:)
        expect(asset.aliquots).to all(have_attributes(library_type: library_type.name))
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::ReferenceGenome do
    it 'is valid, if a value was not provided' do
      expect(described_class.new(sample_manifest_asset:)).to be_valid
    end

    it 'does not be valid without a persisted reference genome if a value is provided' do
      expect(
        described_class.new(value: reference_genome.name, sample_manifest_asset:)
      ).to be_valid
      expect(
        described_class.new(value: 'A new reference genome', sample_manifest_asset:)
      ).not_to be_valid
    end

    it 'adds reference genome to sample_metadata' do
      specialised_field =
        described_class.new(value: reference_genome.name, sample_manifest_asset:)
      specialised_field.update
      expect(sample_manifest_asset.sample.sample_metadata.reference_genome).to eq(reference_genome)
    end
  end

  describe SequencescapeExcel::SpecialisedField::Volume do
    let(:value) { '13' }
    let(:value2) { '8' }

    it 'updates the volume in sample metadata' do
      specialised_field = described_class.new(value:, sample_manifest_asset:)
      specialised_field.update
      expect(sample_manifest_asset.sample.sample_metadata.volume).to eq(value)
    end

    it 'creates a QC result for the asset' do
      specialised_field = described_class.new(value:, sample_manifest_asset:)
      specialised_field.update
      qc_result = sample_manifest_asset.asset.qc_results.first
      expect(qc_result.value).to eq(value.to_f.to_s)
      expect(qc_result.assay_type).to eq('customer_supplied')
      expect(qc_result.key).to eq('volume')
      expect(qc_result.units).to eq('ul')
    end

    it 'creates a QC assay for each sample manifest' do
      specialised_field1 = described_class.new(value:, sample_manifest_asset:)
      specialised_field1.update
      specialised_field2 = described_class.new(value: value2, sample_manifest_asset: sample_manifest_asset2)
      specialised_field2.update
      qc_assay = QcAssay.find_by(lot_number: "sample_manifest_id:#{sample_manifest.id}")
      qc_result1 = sample_manifest_asset.asset.qc_results.first
      qc_result2 = sample_manifest_asset2.asset.qc_results.first
      expect(qc_result1.qc_assay).to eq(qc_assay)
      expect(qc_result2.qc_assay).to eq(qc_assay)
    end

    it 'does not create QC results for the asset if the value is blank' do
      specialised_field = described_class.new(value: nil, sample_manifest_asset:)
      specialised_field.update
      qc_result = sample_manifest_asset.asset.qc_results.first
      expect(qc_result).to be_nil
    end

    it 'does not create QC assays for the asset if the value is blank' do
      specialised_field = described_class.new(value: nil, sample_manifest_asset:)
      specialised_field.update
      qc_assay = QcAssay.find_by(lot_number: "sample_manifest_id:#{sample_manifest.id}")
      expect(qc_assay).to be_nil
    end
  end

  describe SequencescapeExcel::SpecialisedField::InsertSizeFrom do
    it 'value must be a valid number greater than 0' do
      expect(described_class.new(value: 'zero', sample_manifest_asset:)).not_to be_valid
      expect(described_class.new(value: -1, sample_manifest_asset:)).not_to be_valid
    end

    it 'adds the value to the aliquot' do
      specialised_field = described_class.new(value: 100, sample_manifest_asset:)
      specialised_field.update(aliquot:)
      expect(aliquot.insert_size_from).to eq(100)
    end

    context 'with multiple aliquots' do
      let(:asset) { create(:tagged_well, map:, aliquot_count: 2) }

      it 'adds the the value to all aliquots' do
        specialised_field = described_class.new(value: 100, sample_manifest_asset:)
        specialised_field.update(aliquot:)
        expect(asset.aliquots).to all(have_attributes(insert_size_from: 100))
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::InsertSizeTo do
    it 'value must be a valid number greater than 0' do
      expect(described_class.new(value: 'zero', sample_manifest_asset:)).not_to be_valid
      expect(described_class.new(value: -1, sample_manifest_asset:)).not_to be_valid
    end

    it 'adds the value to the aliquot' do
      specialised_field = described_class.new(value: 100, sample_manifest_asset:)
      specialised_field.update(aliquot:)
      expect(aliquot.insert_size_to).to eq(100)
    end

    context 'with multiple aliquots' do
      let(:asset) { create(:tagged_well, map:, aliquot_count: 2) }

      it 'adds the the value to all aliquots' do
        specialised_field = described_class.new(value: 100, sample_manifest_asset:)
        specialised_field.update(aliquot:)
        expect(asset.aliquots).to all(have_attributes(insert_size_to: 100))
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::SangerPlateId do
    let!(:sample1) { create(:sample_with_well) }
    let!(:sample1_plate) { sample1.wells.first.plate }
    let(:sample_manifest_asset1) { create(:sample_manifest_asset, asset: sample1.primary_receptacle) }

    it 'is valid if the value matches the sanger human barcode' do
      expect(
        described_class.new(value: sample1_plate.human_barcode, sample_manifest_asset: sample_manifest_asset1)
      ).to be_valid
      expect(described_class.new(value: '1234', sample_manifest_asset: sample_manifest_asset1)).not_to be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample2) { create(:sample_with_well) }
      let(:sample_manifest_asset2) { create(:sample_manifest_asset, asset: sample2.primary_receptacle) }

      it 'is valid if the value matches an unused cgap foreign barcode' do
        expect(described_class.new(value: 'CGAP-ABC001', sample_manifest_asset: sample_manifest_asset1)).to be_valid
      end

      it 'does not be valid if the value matches an already used cgap foreign barcode' do
        sample1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(described_class.new(value: 'CGAP-ABC011', sample_manifest_asset: sample_manifest_asset2)).not_to be_valid
      end

      it 'is valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = described_class.new(value: 'CGAP-ABC022', sample_manifest_asset: sample_manifest_asset1)
        expect(field).to be_valid

        field.update(aliquot: sample1.wells.first.aliquots.first)

        sample1_plate.reload
        expect(sample1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).not_to be_nil
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::SangerSampleId do
    it 'sets the sanger sample id from the sample' do
      expect(described_class.new(value: '1234', sample_manifest_asset:).value).to eq('1234')
    end
  end

  describe SequencescapeExcel::SpecialisedField::SangerTubeId do
    let!(:sample1) { create(:sample) }
    let!(:sample1_tube) { create(:sample_tube_with_sanger_sample_id, sample: sample1) }

    let(:manifest_asset) { create(:sample_manifest_asset, asset: sample1_tube) }

    it 'is valid if the value matches the sanger human barcode' do
      expect(described_class.new(value: sample1_tube.human_barcode, sample_manifest_asset: manifest_asset)).to be_valid
      expect(described_class.new(value: '1234', sample_manifest_asset: manifest_asset)).not_to be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample2) { create(:sample) }
      let!(:sample2_tube) { create(:sample_tube_with_sanger_sample_id, sample: sample2) }
      let(:manifest_asset2) { create(:sample_manifest_asset, asset: sample2_tube) }

      it 'is valid if the value matches an unused cgap foreign barcode' do
        expect(described_class.new(value: 'CGAP-ABC001', sample_manifest_asset: manifest_asset)).to be_valid
      end

      it 'does not be valid if the value matches an already used cgap foreign barcode' do
        sample1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(described_class.new(value: 'CGAP-ABC011', sample_manifest_asset: manifest_asset2)).not_to be_valid
      end

      it 'is valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = described_class.new(value: 'CGAP-ABC022', sample_manifest_asset: manifest_asset)
        expect(field).to be_valid

        field.update(aliquot: sample1_tube.aliquots.first)

        sample1_tube.reload
        expect(sample1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).not_to be_nil
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::Well do
    it 'does not be valid unless the value matches the well description' do
      expect(described_class.new(value: 'well', sample_manifest_asset:)).not_to be_valid
      expect(
        described_class.new(
          value: sample_manifest_asset.asset.map_description,
          sample_manifest_asset:
        )
      ).to be_valid
    end
  end

  describe SequencescapeExcel::SpecialisedField::SampleEbiAccessionNumber do
    it 'does not be valid if the value is different to the sample accession number' do
      expect(described_class.new(value: '', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: 'EB123', sample_manifest_asset:)).to be_valid
      sample_manifest_asset.sample.sample_metadata.sample_ebi_accession_number = 'EB123'
      expect(described_class.new(value: '', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: 'EB1234', sample_manifest_asset:)).not_to be_valid
      expect(described_class.new(value: 'EB123', sample_manifest_asset:)).to be_valid
    end
  end

  describe SampleManifestExcel::Tags do
    let!(:tag_group) { create(:tag_group) }
    let(:oligo) { 'AA' }

    describe SequencescapeExcel::SpecialisedField::I7 do
      let(:i7) { described_class.new(value: oligo, sample_manifest_asset:) }

      it 'is valid if the tag contains just A, C, G or T' do
        expect(described_class.new(value: 'ACGT', sample_manifest_asset:)).to be_valid
        expect(described_class.new(value: 'acgt', sample_manifest_asset:)).to be_valid
        expect(described_class.new(value: 'acgt', sample_manifest_asset:)).to be_valid
        expect(described_class.new(value: 'aatc', sample_manifest_asset:)).to be_valid
      end

      it 'does not be valid if the tag does not contain A, C, G or T' do
        expect(described_class.new(value: 'ACGT ACGT', sample_manifest_asset:)).not_to be_valid
        expect(described_class.new(value: 'BCGT', sample_manifest_asset:)).not_to be_valid
        expect(described_class.new(value: '-CGT', sample_manifest_asset:)).not_to be_valid
        expect(described_class.new(value: 'xCGT', sample_manifest_asset:)).not_to be_valid
      end

      it 'adds the value' do
        expect(i7.value).to eq(oligo)
      end

      it 'updates the aliquot and create the tag if oligo is present' do
        i7.update(aliquot:, tag_group:)
        tag = tag_group.tags.find_by(oligo:)
        expect(tag).to be_present
        expect(tag.oligo).to eq(oligo)
        expect(tag.map_id).to eq(1)
        expect(aliquot.tag).to eq(tag)
      end

      it 'if oligo is not present aliquot tag should be -1' do
        i7 = described_class.new(value: nil, sample_manifest_asset:)
        i7.update(aliquot:, tag_group:)
        aliquot.save
        expect(aliquot.tag_id).to eq(-1)
      end

      it 'finds the tag if it already exists' do
        tag = tag_group.tags.create(oligo:, map_id: 10)
        i7.update(aliquot:, tag_group:)
        expect(aliquot.tag).to eq(tag)
      end
    end

    describe SequencescapeExcel::SpecialisedField::I5 do
      let(:i5) { described_class.new(value: oligo, sample_manifest_asset:) }

      it 'does not be valid if the tag does not contain A, C, G or T' do
        expect(described_class.new(value: 'ACGT', sample_manifest_asset:)).to be_valid
        expect(described_class.new(value: 'BCGT', sample_manifest_asset:)).not_to be_valid
      end

      it 'adds the value' do
        expect(i5.value).to eq(oligo)
      end

      it 'updates the aliquot' do
        i5.update(aliquot:, tag_group:)
        aliquot.save
        expect(aliquot.tag2).to eq(tag_group.tags.find_by(oligo:))
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::TagGroup do
    let!(:tag_group) { create(:tag_group_with_tags) }
    let!(:tag2_group) { create(:tag_group_with_tags) }
    let(:tag_group_name) { tag_group.name }
    let(:tag2_group_name) { tag2_group.name }
    let(:tag_index) { tag_group.tags[0].map_id }
    let(:tag2_index) { tag2_group.tags[0].map_id }

    describe 'tag group' do
      it 'adds the value' do
        sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset:)
        expect(sf_tag_group.value).to eq(tag_group_name)
      end

      it 'is valid with an existing tag group name' do
        expect(described_class.new(value: tag_group_name, sample_manifest_asset:)).to be_valid
      end

      it 'does not be valid without an existing tag group name' do
        expect(described_class.new(value: 'unknown', sample_manifest_asset:)).not_to be_valid
      end

      it 'responds to update method but does nothing to tag on aliquot' do
        sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset:)
        expect(sf_tag_group.update(aliquot:, tag_group: nil)).to be_nil
        aliquot.save
        expect(aliquot.tag).to be_nil
      end
    end

    describe SequencescapeExcel::SpecialisedField::TagIndex do
      it 'adds the value' do
        sf_tag_index = described_class.new(value: tag_index, sample_manifest_asset:)
        expect(sf_tag_index.value).to eq(tag_index)
      end

      it 'does not have a valid tag index when unlinked from a tag group' do
        expect(described_class.new(value: tag_index, sample_manifest_asset:)).not_to be_valid
      end

      describe 'linking' do
        let!(:sf_tag_group) do
          SequencescapeExcel::SpecialisedField::TagGroup.new(
            value: tag_group_name,
            sample_manifest_asset:
          )
        end
        let!(:sf_tag_index) { described_class.new(value: tag_index, sample_manifest_asset:) }

        before { sf_tag_index.sf_tag_group = sf_tag_group }

        it 'has a valid tag index when linked to a tag group' do
          expect(sf_tag_index).to be_valid
        end

        it 'does not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag_index2 = described_class.new(value: 10, sample_manifest_asset:)
          sf_tag_index2.sf_tag_group = sf_tag_group
          expect(sf_tag_index2).not_to be_valid
        end

        it 'updates the aliquot with tag if its oligo is present' do
          sf_tag_index.update(aliquot:, tag_group: nil)
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
          expect(tag.oligo).to be_nil
          sf_tag_index.update(aliquot:, tag_group: nil)
          aliquot.save
          expect(aliquot.tag_id).to eq(-1)
        end
      end
    end

    describe SequencescapeExcel::SpecialisedField::Tag2Group do
      it 'adds the value' do
        sf_tag2_group = described_class.new(value: tag2_group_name, sample_manifest_asset:)
        expect(sf_tag2_group.value).to eq(tag2_group_name)
      end

      it 'is valid with an existing tag2 group name' do
        expect(described_class.new(value: tag2_group_name, sample_manifest_asset:)).to be_valid
      end

      it 'does not be valid without an existing tag2 group name' do
        expect(described_class.new(value: 'unknown', sample_manifest_asset:)).not_to be_valid
      end

      it 'responds to update method but does nothing to tag2 on aliquot' do
        sf_tag2_group = described_class.new(value: tag2_group_name, sample_manifest_asset:)
        expect(sf_tag2_group.update(aliquot:, tag_group: nil)).to be_nil
        aliquot.save
        expect(aliquot.tag2).to be_nil
      end
    end

    describe SequencescapeExcel::SpecialisedField::Tag2Index do
      it 'adds the value' do
        sf_tag2_index = described_class.new(value: tag2_index, sample_manifest_asset:)
        expect(sf_tag2_index.value).to eq(tag2_index)
      end

      it 'does not have a valid tag index when unlinked from a tag group' do
        expect(described_class.new(value: tag2_index, sample_manifest_asset:)).not_to be_valid
      end

      context 'when value and index are nil and tag exists that matches based on nil values' do
        let!(:sf_tag2_group) { SequencescapeExcel::SpecialisedField::Tag2Group.new(value: nil) }
        let!(:sf_tag2_index) { described_class.new(value: nil) }

        before do
          sf_tag2_index.sf_tag2_group = sf_tag2_group
          Tag.create(oligo: 'XXXXXXXX')
        end

        it 'does not retrieve nil tag' do
          expect(sf_tag2_index).to be_valid
          sf_tag2_index.update(aliquot:)
          expect(aliquot.tag2_id).to eq(-1)
        end
      end

      describe 'linking' do
        let!(:sf_tag2_group) do
          SequencescapeExcel::SpecialisedField::Tag2Group.new(
            value: tag2_group_name,
            sample_manifest_asset:
          )
        end
        let!(:sf_tag2_index) { described_class.new(value: tag2_index, sample_manifest_asset:) }

        before { sf_tag2_index.sf_tag2_group = sf_tag2_group }

        it 'has a valid tag index when linked to a tag group' do
          expect(sf_tag2_index).to be_valid
        end

        it 'does not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag2_index2 = described_class.new(value: 10, sample_manifest_asset:)
          sf_tag2_index2.sf_tag2_group = sf_tag2_group
          expect(sf_tag2_index2).not_to be_valid
        end

        it 'updates the aliquot with tag2 if its oligo is present' do
          sf_tag2_index.update(aliquot:, tag_group: nil)
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
          expect(tag2.oligo).to be_nil
          sf_tag2_index.update(aliquot:, tag_group: nil)
          aliquot.save
          expect(aliquot.tag2_id).to eq(-1)
        end
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::ChromiumTagGroup do
    let(:adapter_type) { create(:adapter_type, name: 'Chromium') }
    let(:tag_group) { create(:tag_group_with_tags, adapter_type:) }
    let(:tag_group_name) { tag_group.name }
    let(:tag_well) { 'A1' }

    describe 'tag group' do
      it 'adds the value' do
        sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset:)
        expect(sf_tag_group.value).to eq(tag_group_name)
      end

      it 'is valid with an existing tag group name' do
        expect(described_class.new(value: tag_group_name, sample_manifest_asset:)).to be_valid
      end

      context 'when the tag group is not Chromium' do
        let(:adapter_type) { create(:adapter_type, name: 'Other') }

        it 'does not be valid' do
          expect(
            described_class.new(value: tag_group_name, sample_manifest_asset:)
          ).not_to be_valid
        end
      end

      it 'responds to update method but does nothing to tag on aliquot' do
        sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset:)
        expect(sf_tag_group.update(aliquot:, tag_group: nil)).to be_nil
        aliquot.save
        expect(aliquot.tag).to be_nil
      end
    end

    describe SequencescapeExcel::SpecialisedField::ChromiumTagWell do
      it 'adds the value' do
        sf_tag_well = described_class.new(value: tag_well, sample_manifest_asset:)
        expect(sf_tag_well.value).to eq(tag_well)
      end

      it 'does not have a valid tag index when unlinked from a tag group' do
        expect(described_class.new(value: tag_well, sample_manifest_asset:)).not_to be_valid
      end

      describe 'linking' do
        let(:sf_tag_group) do
          SequencescapeExcel::SpecialisedField::ChromiumTagGroup.new(
            value: tag_group_name,
            sample_manifest_asset:
          )
        end
        let(:sf_tag_well) { described_class.new(value: tag_well, sample_manifest_asset:) }

        before { sf_tag_well.sf_tag_group = sf_tag_group }

        it 'has a valid tag index when linked to a tag group' do
          expect(sf_tag_well).to be_valid
        end

        context 'when well name is invalid' do
          let(:tag_well) { 'sausage' }

          it 'does not have a valid tag index when index does not match to a map_id in the tag group' do
            expect(sf_tag_well).not_to be_valid
          end
        end

        it 'applies the four tags associated with the map_id' do
          sf_tag_well.update(aliquot:, tag_group: nil)
          expect(asset.aliquots.map { |a| a.tag.map_id }).to contain_exactly(1, 2, 3, 4)
        end

        context 'when applied to a re-upload' do
          let(:asset) { create(:tagged_well, map:, aliquot_count: 4) }

          it 'applies the four tags associated with the map_id' do
            sf_tag_well.update(aliquot:, tag_group: nil)
            expect(asset.aliquots.map { |a| a.tag.map_id }).to contain_exactly(1, 2, 3, 4)
          end
        end
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::PrimerPanel do
    let(:primer_panel) { create(:primer_panel) }

    it 'does not be valid without a persisted primer panel' do
      expect(described_class.new(value: primer_panel.name, sample_manifest_asset:)).to be_valid
      expect(
        described_class.new(value: 'A new primer panel', sample_manifest_asset:)
      ).not_to be_valid
    end

    it 'is valid if blank' do
      expect(described_class.new(value: '', sample_manifest_asset:)).to be_valid
    end

    it 'adds the the value to the aliquot' do
      specialised_field = described_class.new(value: primer_panel.name, sample_manifest_asset:)
      specialised_field.update(aliquot:)
      expect(aliquot.primer_panel).to eq(primer_panel)
    end

    context 'with multiple aliquots' do
      let(:asset) { create(:tagged_well, map:, aliquot_count: 2) }

      it 'adds the the value to all aliquots' do
        specialised_field = described_class.new(value: primer_panel.name, sample_manifest_asset:)
        specialised_field.update(aliquot:)
        expect(asset.aliquots).to all(have_attributes(primer_panel:))
      end
    end
  end

  describe SequencescapeExcel::SpecialisedField::Priority do
    it 'is valid if value blank string or nil' do
      expect(described_class.new(value: '', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: nil, sample_manifest_asset:)).to be_valid
    end

    it 'is valid if value matches enum' do
      expect(described_class.new(value: '0', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: '1', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: '2', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: '3', sample_manifest_asset:)).to be_valid
    end

    it 'does not be valid if value does not match enum' do
      sf = described_class.new(value: '5', sample_manifest_asset:)
      expect(sf).not_to be_valid
      expect(sf.errors.full_messages.join).to include('the priority 5 was not recognised.')
    end

    it 'updates the priority on the sample when present' do
      specialised_field = described_class.new(value: '1', sample_manifest_asset:)
      specialised_field.update(aliquot:)
      aliquot.save
      expect(sample_manifest_asset.sample.priority).to eq('backlog')
    end
  end

  describe SequencescapeExcel::SpecialisedField::ControlType do
    it 'is valid if value blank string or nil' do
      expect(described_class.new(value: '', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: nil, sample_manifest_asset:)).to be_valid
    end

    it 'is valid if value matches enum' do
      expect(described_class.new(value: 'positive', sample_manifest_asset:)).to be_valid
      expect(described_class.new(value: 'negative', sample_manifest_asset:)).to be_valid
    end

    it 'does not be valid if value does not match enum' do
      sf = described_class.new(value: 'rubbish', sample_manifest_asset:)
      expect(sf).not_to be_valid
      expect(sf.errors.full_messages).to include('the control type rubbish was not recognised.')
    end

    it 'updates the control and control type on the sample when present' do
      specialised_field = described_class.new(value: 'positive', sample_manifest_asset:)
      specialised_field.update(aliquot:)
      aliquot.save
      expect(sample_manifest_asset.sample.control).to be(true)
      expect(sample_manifest_asset.sample.control_type).to eq('positive')
    end

    # test to allow a re-upload to correct a previously set control to not a control
    it 'updates the control and control type on the sample when blank' do
      sample_manifest_asset.sample.control = true
      sample_manifest_asset.sample.control_type = 'positive'
      sample_manifest_asset.sample.save
      specialised_field = described_class.new(value: '', sample_manifest_asset:)
      specialised_field.update(aliquot:)
      aliquot.save
      expect(sample_manifest_asset.sample.control).to be(false)
      expect(sample_manifest_asset.sample.control_type).to be_nil
    end
  end

  # This section for the Bioscan specific control type field
  describe SequencescapeExcel::SpecialisedField::BioscanControlType do
    let(:sample_supplier_name) { 'CONTROL_test_01' }
    let!(:bs_supplier_name) do
      SequencescapeExcel::SpecialisedField::BioscanSupplierName.new(
        value: sample_supplier_name,
        sample_manifest_asset:
      )
    end
    let!(:sf_well) do
      SequencescapeExcel::SpecialisedField::Well.new(value: 'H12', sample_manifest_asset:)
    end

    # test value matches to the enum in the sample model
    # for Bioscan we have three types of control
    it 'is valid if value matches enum' do
      sf_pcr_pos = described_class.new(value: 'pcr positive', sample_manifest_asset:)
      sf_pcr_pos.supplier_name = bs_supplier_name
      expect(sf_pcr_pos).to be_valid

      sf_pcr_neg = described_class.new(value: 'pcr negative', sample_manifest_asset:)
      sf_pcr_neg.supplier_name = bs_supplier_name
      expect(sf_pcr_neg).to be_valid

      sf_lysate_neg = described_class.new(value: 'lysate negative', sample_manifest_asset:)
      sf_lysate_neg.supplier_name = bs_supplier_name
      sf_lysate_neg.well = sf_well
      expect(sf_lysate_neg).to be_valid
    end

    # test field is not valid if value does not match to the enum in the sample model
    it 'does not be valid if value does not match enum' do
      sf = described_class.new(value: 'rubbish', sample_manifest_asset:)
      sf.supplier_name = bs_supplier_name

      expect(sf).not_to be_valid
      expect(sf.errors.full_messages).to include('the control type rubbish was not recognised.')
    end

    # test control flag and type are set on sample
    it 'updates the control and control type on the sample when present' do
      sf = described_class.new(value: 'pcr positive', sample_manifest_asset:)
      sf.supplier_name = bs_supplier_name
      sf.update(aliquot:)
      aliquot.save
      expect(sample_manifest_asset.sample.control).to be(true)
      expect(sample_manifest_asset.sample.control_type).to eq('pcr positive')
    end

    # test to allow a re-upload to correct a previously set control to not a control
    it 'updates the control and control type on the sample when blank' do
      sample_manifest_asset.sample.control = true
      sample_manifest_asset.sample.control_type = 'pcr positive'
      sample_manifest_asset.sample.save
      sf = described_class.new(value: '', sample_manifest_asset:)
      sf.supplier_name = bs_supplier_name
      sf.update(aliquot:)
      aliquot.save
      expect(sample_manifest_asset.sample.control).to be(false)
      expect(sample_manifest_asset.sample.control_type).to be_nil
    end

    context 'when pcr positive in H12' do
      let!(:bs_well) do
        SequencescapeExcel::SpecialisedField::Well.new(value: 'H12', sample_manifest_asset:)
      end

      it 'is invalid' do
        control_type_sf = described_class.new(value: 'pcr positive', sample_manifest_asset:)
        control_type_sf.supplier_name = bs_supplier_name
        control_type_sf.well = bs_well
        expect(control_type_sf).not_to be_valid
      end
    end

    context 'when pcr positive not in H12' do
      let!(:bs_well) do
        SequencescapeExcel::SpecialisedField::Well.new(value: 'A1', sample_manifest_asset:)
      end

      it 'is valid' do
        control_type_sf = described_class.new(value: 'pcr positive', sample_manifest_asset:)
        control_type_sf.supplier_name = bs_supplier_name
        control_type_sf.well = bs_well
        expect(control_type_sf).to be_valid
      end
    end

    context 'when lysate negative in H12' do
      let!(:bs_well) do
        SequencescapeExcel::SpecialisedField::Well.new(value: 'H12', sample_manifest_asset:)
      end

      it 'is valid' do
        control_type_sf = described_class.new(value: 'lysate negative', sample_manifest_asset:)
        control_type_sf.supplier_name = bs_supplier_name
        control_type_sf.well = bs_well
        expect(control_type_sf).to be_valid
      end
    end

    context 'when lysate negative not in H12' do
      let!(:bs_well) do
        SequencescapeExcel::SpecialisedField::Well.new(value: 'A1', sample_manifest_asset:)
      end

      it 'is invalid' do
        control_type_sf = described_class.new(value: 'lysate negative', sample_manifest_asset:)
        control_type_sf.supplier_name = bs_supplier_name
        control_type_sf.well = bs_well
        expect(control_type_sf).not_to be_valid
      end
    end
  end

  # This section for the Bioscan specific supplier name field
  # This specialised field is very simple, a string. We need it for validation
  # checks when a Bioscan control type has been selected (must start CONTROL_).
  # That validation is tested in the BioscanControlType tests above.
  describe SequencescapeExcel::SpecialisedField::BioscanSupplierName do
    let(:sample_supplier_name) { 'test_name' }

    # supplier name is a primary field and must be present in the manifest rows
    it 'does not be valid if blank' do
      expect(described_class.new(value: '', sample_manifest_asset:)).not_to be_valid
    end

    # test supplier name is stored in the sample metadata on update
    it 'adds supplier name to sample_metadata' do
      sf = described_class.new(value: sample_supplier_name, sample_manifest_asset:)
      sf.update
      expect(sample_manifest_asset.sample.sample_metadata.supplier_name).to eq(sample_supplier_name)
    end
  end

  # This section is for the Retention instruction field added as part of the Labware Destruction work
  describe SequencescapeExcel::SpecialisedField::RetentionInstruction do
    let(:user) { create(:user) }

    shared_examples 'a retention instruction labware' do
      it 'is invalid if the value is not set' do
        sf = described_class.new(value: nil, sample_manifest_asset:)

        expect(sf).not_to be_valid
        expect(sf.errors.full_messages.join).to include('Retention instruction can\'t be blank')
      end

      it 'is valid if the value matches one of the expected values' do
        expect(
          described_class.new(value: 'Long term storage', sample_manifest_asset:)
        ).to be_valid
      end

      it 'creates labware custom metadata on the labware and set the retention instruction choice' do
        sf = described_class.new(value: 'Long term storage', sample_manifest_asset:)
        sf.update

        expect(sf.asset.labware.custom_metadatum_collection&.metadata&.values&.count).to eq(1)
        expect(sf.asset.labware.custom_metadatum_collection&.metadata&.values).to include('Long term storage')
      end

      it 'updates any existing labware custom metadata on the labware to add the retention instruction choice' do
        cm =
          CustomMetadatumCollection.new(
            user: sample_manifest.user,
            asset: asset.labware,
            metadata: {
              'some_existing_metadata' => 'some_value'
            }
          )
        asset.labware.custom_metadatum_collection = cm
        cm.save

        sf = described_class.new(value: 'Long term storage', sample_manifest_asset:)
        sf.update

        expect(sf.asset.labware.custom_metadatum_collection.metadata.values.count).to eq(2)
        expect(sf.asset.labware.custom_metadatum_collection.metadata.values).to include('Long term storage')
      end

      # It is valid for this special field to update the labware metadata and change it to a new value.
      # As long as the validation on the manifest re-upload passes (and for a plate that all wells for a labware
      # have the same retention instruction value, it is valid to update.
      it 'is valid to update if the labware already contains a retention instruction metadata' do
        cm =
          CustomMetadatumCollection.new(
            user: sample_manifest.user,
            asset: asset.labware,
            metadata: {
              'retention_instruction' => 'Long term storage'
            }
          )
        asset.labware.custom_metadatum_collection = cm
        cm.save

        sf = described_class.new(value: 'Destroy after 2 years', sample_manifest_asset:)
        expect(sf).to be_valid
        sf.update

        expect(cm.metadata['retention_instruction']).to eq('Destroy after 2 years')
      end
    end

    context 'when processing plate wells' do
      let(:asset_plate) { create(:plate_with_untagged_wells, sample_count: 1) }
      let(:asset) { asset_plate.wells.first }

      it_behaves_like 'a retention instruction labware'
    end

    context 'when processing tubes' do
      let(:asset) { create(:sample_tube) }

      it_behaves_like 'a retention instruction labware'
    end
  end
end
