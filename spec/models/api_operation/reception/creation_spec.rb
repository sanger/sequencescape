# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Creation do
  subject(:creation) { described_class.new(payload.labware) }

  let(:payload) do
    ApiOperation::Reception::Payload.new({ labware: }.to_json)
  end
  let(:created) { Barcode.find_by!(barcode: 'SAPIO-1').asset }
  let(:study) { create(:study) }

  before do
    create(:input_plate_purpose, name: 'Library Stock Plate')
    allow(PlateBarcode).to receive(:create_barcode)
    creation.call
  end

  # A payload sample, with the optional fields given
  def sample(**fields)
    { uuid: SecureRandom.uuid, study_uuid: study.uuid,
      sanger_sample_id: "SAMPLE-#{SecureRandom.hex(4)}",
      supplier_sample_name: 'Supplier sample' }.merge(fields)
  end

  # A payload plate with a sample in each well from A1 down the first column
  def plate(barcode, *samples)
    receptacles = samples.each_with_index.map do |sample, index|
      { position: "#{('A'.ord + index).chr}1", uuid: SecureRandom.uuid,
        samples: [sample] }
    end
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles }
  end

  # A payload tube holding the samples
  def tube(barcode, *samples)
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'tube',
      receptacles: [{ position: nil, uuid: SecureRandom.uuid,
                      samples: samples }] }
  end

  context 'with a plate whose samples have no tags' do
    let(:labware) { [plate('SAPIO-1', sample, sample)] }

    it 'creates a Stock Plate named after its barcode' do
      expect(created).to have_attributes(
        class: Plate, name: 'Plate SAPIO-1', size: 96,
        purpose: have_attributes(name: 'Stock Plate')
      )
    end

    it 'gives it only the barcode it arrived with' do
      expect(created.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-1]])
    end

    it 'does not ask Baracoda for a barcode' do
      expect(PlateBarcode).not_to have_received(:create_barcode)
    end

    it 'gives it its wells' do
      expect(created.wells.count).to eq(96)
    end
  end

  context 'with a plate whose samples have tags' do
    let(:labware) { [plate('SAPIO-1', sample(i7: 'ACGT'), sample)] }

    it 'creates a Library Stock Plate' do
      expect(created.purpose.name).to eq('Library Stock Plate')
    end
  end

  context 'with a tube of a sample without tags' do
    let(:labware) { [tube('SAPIO-1', sample)] }

    it 'creates a Standard sample tube' do
      expect(created).to be_a(SampleTube).and have_attributes(
        purpose: have_attributes(name: 'Standard sample')
      )
    end

    it 'gives it only the barcode it arrived with' do
      expect(created.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-1]])
    end
  end

  context 'with a tube of samples without tags' do
    let(:labware) { [tube('SAPIO-1', sample, sample)] }

    it 'creates a Standard sample tube' do
      expect(created.purpose.name).to eq('Standard sample')
    end
  end

  context 'with a tube of a sample with tags' do
    let(:labware) do
      [tube('SAPIO-1', sample(tag_group: 'Group', tag_index: 1))]
    end

    it 'creates a Standard library tube' do
      expect(created).to be_a(LibraryTube).and have_attributes(
        purpose: have_attributes(name: 'Standard library')
      )
    end
  end

  context 'with a tube of samples with tags' do
    let(:labware) do
      [tube('SAPIO-1', sample(i7: 'ACGT'), sample(i7: 'TGCA'))]
    end

    it 'creates a Standard MX tube' do
      expect(created).to be_a(MultiplexedLibraryTube).and have_attributes(
        purpose: have_attributes(name: 'Standard MX')
      )
    end
  end

  context 'with several labware' do
    let(:labware) do
      [plate('SAPIO-1', sample), tube('SAPIO-2', sample),
       tube('SAPIO-3', sample)]
    end

    it 'creates each' do
      expect(Barcode.where(barcode: %w[SAPIO-1 SAPIO-2 SAPIO-3]).count)
        .to eq(3)
    end
  end

  describe 'samples' do
    let(:created_sample) { Sample.find_by!(sanger_sample_id: 'SAMPLE-1') }
    let(:uuid) { SecureRandom.uuid }

    context 'with a sample' do
      let(:labware) do
        [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1', uuid: uuid))]
      end

      it 'creates it, externally managed, with the payload UUID' do
        expect(created_sample).to have_attributes(
          name: 'SAMPLE-1', uuid: uuid, externally_managed: true,
          studies: contain_exactly(study),
          priority: 'no_priority', control: false
        )
      end

      it 'gives it the supplier sample name' do
        expect(created_sample.sample_metadata.supplier_name)
          .to eq('Supplier sample')
      end
    end

    context 'with a sample in two receptacles' do
      let(:replicate) { sample(sanger_sample_id: 'SAMPLE-1') }
      let(:labware) { [plate('SAPIO-1', replicate, replicate)] }

      it 'creates it once' do
        expect(Sample.where(sanger_sample_id: 'SAMPLE-1').count).to eq(1)
      end
    end

    context 'with UUIDs in upper case' do
      let(:labware) do
        [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                uuid: uuid.upcase,
                                study_uuid: study.uuid.upcase))]
      end

      it 'keeps the sample UUID in lower case' do
        expect(created_sample.uuid).to eq(uuid)
      end

      it 'finds the study' do
        expect(created_sample.studies).to contain_exactly(study)
      end
    end

    context 'with optional fields' do
      let(:reference_genome) { create(:reference_genome) }
      let(:labware) do
        [tube('SAPIO-1',
              sample(sanger_sample_id: 'SAMPLE-1', priority: 'surveillance',
                     control_type: 'positive', donor_id: 'DONOR-1',
                     reference_genome: reference_genome.name.upcase))]
      end

      it 'sets them on the sample' do
        expect(created_sample).to have_attributes(
          priority: 'surveillance', control: true, control_type: 'positive'
        )
      end

      it 'sets them in its metadata' do
        expect(created_sample.sample_metadata).to have_attributes(
          donor_id: 'DONOR-1', reference_genome: reference_genome
        )
      end
    end

    context 'with Bioscan fields' do
      let(:labware) do
        [plate('SAPIO-1',
               sample(sanger_sample_id: 'SAMPLE-1',
                      bioscan_supplier_name: 'CONTROL_1',
                      bioscan_control_type: 'pcr positive'))]
      end

      it 'uses the Bioscan supplier name and control type' do
        expect(created_sample).to have_attributes(
          control: true, control_type: 'pcr positive',
          sample_metadata: have_attributes(supplier_name: 'CONTROL_1')
        )
      end
    end
  end

  describe 'aliquots' do
    let(:created_sample) { Sample.find_by!(sanger_sample_id: 'SAMPLE-1') }

    context 'with a sample in a well' do
      let(:labware) do
        [plate('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1'))]
      end

      it 'puts it in its well, with its study' do
        expect(created_sample.aliquots.sole).to have_attributes(
          receptacle: created.wells.located_at('A1').sole,
          study: study, library: nil, tag_depth: 1
        )
      end
    end

    context 'with library fields' do
      let(:library_type) { create(:library_type) }
      let(:primer_panel) { create(:primer_panel) }
      let(:labware) do
        [tube('SAPIO-1',
              sample(sanger_sample_id: 'SAMPLE-1',
                     library_type: library_type.name.upcase,
                     insert_size_from: 100, insert_size_to: 200,
                     primer_panel: primer_panel.name.upcase))]
      end

      it 'sets them on the aliquot, with the library type by its own name' do
        expect(created_sample.aliquots.sole).to have_attributes(
          library_type: library_type.name, insert_size_from: 100,
          insert_size_to: 200, primer_panel: primer_panel
        )
      end
    end

    context 'with a long read library type' do
      let(:library_type) { create(:library_type) }
      let(:labware) do
        [tube('SAPIO-1',
              sample(sanger_sample_id: 'SAMPLE-1',
                     library_type_long_read: library_type.name))]
      end

      it 'sets the library type' do
        expect(created_sample.aliquots.sole.library_type)
          .to eq(library_type.name)
      end
    end

    context 'with library labware' do
      let(:labware) do
        [plate('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1'),
               sample(i7: 'ACGT'))]
      end

      it "makes the aliquot's well its library" do
        aliquot = created_sample.aliquots.sole
        expect(aliquot.library).to eq(aliquot.receptacle)
      end
    end

    context 'with samples without tags in one tube' do
      let(:labware) do
        [tube('SAPIO-1', *%w[SAMPLE-1 SAMPLE-2 SAMPLE-3].map do |id|
          sample(sanger_sample_id: id)
        end)]
      end

      it 'gives them their positions as tag depths' do
        expect(created.receptacle.aliquots.map do |aliquot|
          [aliquot.sample.sanger_sample_id, aliquot.tag_depth]
        end).to contain_exactly(['SAMPLE-1', 0], ['SAMPLE-2', 1],
                                ['SAMPLE-3', 2])
      end

      it 'gives them no library' do
        expect(created.receptacle.aliquots.map(&:library)).to all(be_nil)
      end
    end

    context 'with a sample in two wells' do
      let(:replicate) { sample(sanger_sample_id: 'SAMPLE-1') }
      let(:labware) { [plate('SAPIO-1', replicate, replicate)] }

      it 'puts it in each well' do
        expect(created_sample.aliquots.map { it.receptacle.map_description })
          .to contain_exactly('A1', 'B1')
      end
    end

    context 'with a sample with a tag group and index' do
      let(:tag_group) { create(:tag_group_with_tags, tag_count: 2) }
      let(:labware) do
        [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                tag_group: tag_group.name, tag_index: 2))]
      end

      it 'gives its aliquot the tag, with the tube as its library' do
        expect(created_sample.aliquots.sole).to have_attributes(
          tag: tag_group.tags.find_by(map_id: 2), tag2: nil,
          library: created.receptacle
        )
      end
    end

    context 'with samples with tags in one tube' do
      let(:tag_group) { create(:tag_group_with_tags, tag_count: 2) }
      let(:labware) do
        [tube('SAPIO-1',
              sample(sanger_sample_id: 'SAMPLE-1',
                     tag_group: tag_group.name, tag_index: 1),
              sample(sanger_sample_id: 'SAMPLE-2',
                     tag_group: tag_group.name, tag_index: 2))]
      end

      it 'gives each aliquot its tag and the default tag depth' do
        expect(created.receptacle.aliquots.map do |aliquot|
          [aliquot.tag.map_id, aliquot.tag_depth]
        end).to contain_exactly([1, 1], [2, 1])
      end
    end

    context 'with a sample with a dual index well' do
      let(:tag_set) do
        create(:tag_set, tag_group: create(:tag_group_with_tags, tag_count: 2),
                         tag2_group: create(:tag_group_with_tags, tag_count: 2))
      end
      let(:labware) do
        [plate('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                 dual_index_tag_set: tag_set.name,
                                 dual_index_tag_well: 'B1'))]
      end

      it 'gives its aliquot both tags of the well' do
        expect(created_sample.aliquots.sole).to have_attributes(
          tag: tag_set.tag_group.tags.find_by(map_id: 2),
          tag2: tag_set.tag2_group.tags.find_by(map_id: 2)
        )
      end
    end

    context 'with a sample with a Chromium well' do
      let(:chromium) { ApiOperation::Reception::Tags::Chromium }
      let(:tag_group) do
        create(:tag_group_with_tags,
               tag_count: 2 * chromium::TAGS_PER_WELL,
               adapter_type: create(:adapter_type, name: 'Chromium'))
      end
      let(:tag_set) { create(:tag_set, tag_group: tag_group, tag2_group: nil) }
      let(:labware) do
        [plate('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                 chromium_tag_group: tag_set.name,
                                 chromium_tag_well: 'B1'))]
      end

      it 'gives it an aliquot for each tag of the well, in its well' do
        expect(created_sample.aliquots.map do |aliquot|
          [aliquot.tag.map_id, aliquot.tag2, aliquot.receptacle.map_description]
        end).to match_array(chromium.map_ids(2).map { [it, nil, 'A1'] })
      end
    end
  end
end
