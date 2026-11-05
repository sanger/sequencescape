# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Creation do
  subject(:creation) { described_class.new(payload.labware, api_operation) }

  let(:payload) do
    ApiOperation::Reception::Payload.new({ labware: }.to_json)
  end
  let(:api_operation) { create(:api_operation) }
  let(:created) { Barcode.find_by!(barcode: 'SAPIO-1').asset }
  let(:study) { create(:study) }

  before do
    create(:input_plate_purpose, name: 'Library Stock Plate')
    allow(PlateBarcode).to receive(:create_barcode)
    # Sample manifests' configuration isn't loaded in tests
    allow(SampleManifestExcel.configuration)
      .to receive(:tag_group).and_return('Magic Tag Group')
    allow(Accession).to receive(:accession_sample)
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

      it 'does not accession it' do
        expect(Accession).not_to have_received(:accession_sample)
      end

      it 'leaves accessioning unpaused afterwards' do
        expect(Sample::Current.temporary_accessioning_pause).to be_nil
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
                     reference_genome: reference_genome.name.upcase,
                     volume: 12.5, concentration: 10, genome_size: 3100))]
      end

      it 'sets them on the sample' do
        expect(created_sample).to have_attributes(
          priority: 'surveillance', control: true, control_type: 'positive'
        )
      end

      it 'sets them in its metadata' do
        expect(created_sample.sample_metadata).to have_attributes(
          donor_id: 'DONOR-1', reference_genome: reference_genome,
          volume: '12.5', concentration: '10', genome_size: 3100
        )
      end
    end

    context 'without optional fields' do
      let(:labware) { [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1'))] }

      it 'leaves the measurements empty in its metadata' do
        expect(created_sample.sample_metadata)
          .to have_attributes(volume: nil, concentration: nil, genome_size: nil)
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

  describe 'volumes' do
    let(:volume_results) do
      QcResult.where(asset: created.receptacles).map do |qc_result|
        [qc_result.asset_id, qc_result.key, qc_result.value, qc_result.units,
         qc_result.assay_type, qc_result.assay_version]
      end
    end

    context 'with a tube of a sample with a volume' do
      let(:labware) { [tube('SAPIO-1', sample(volume: 12.5))] }

      it 'records the volume as a customer-supplied QC result on the tube' do
        expect(volume_results).to eq(
          [[created.receptacle.id, 'volume', '12.5', 'ul', 'customer_supplied',
            'v0.0']]
        )
      end

      it 'puts the QC result in a QC assay named after the operation' do
        expect(created.receptacle.qc_results.sole.qc_assay.lot_number)
          .to eq("api_operation_id:#{api_operation.id}")
      end

      it 'sets the volume of the tube' do
        expect(created.receptacle.reload.volume).to eq(12.5)
      end
    end

    context 'with a plate of samples with volumes' do
      let(:labware) do
        [plate('SAPIO-1', sample(volume: 10), sample(volume: 20))]
      end

      it 'sets the measured volume of each well' do
        expect(created.wells.located_at(%w[A1 B1]).map do |well|
          well.reload.well_attribute.measured_volume
        end).to eq([10.0, 20.0])
      end
    end

    context 'with a tube of samples with volumes' do
      let(:labware) do
        [tube('SAPIO-1', sample(volume: 10), sample(volume: 20))]
      end

      it 'records no QC result, as the volumes are of the samples' do
        expect(volume_results).to be_empty
      end

      it 'keeps each volume in its sample' do
        expect(created.receptacle.samples.map { it.sample_metadata.volume })
          .to contain_exactly('10', '20')
      end
    end

    context 'with a tube of a sample without a volume' do
      let(:labware) { [tube('SAPIO-1', sample)] }

      it 'records no QC result' do
        expect(volume_results).to be_empty
      end
    end
  end

  describe 'concentrations' do
    let(:concentration_results) do
      QcResult.where(asset: created.receptacles, key: 'concentration')
        .map do |qc_result|
          [qc_result.asset_id, qc_result.value, qc_result.units,
           qc_result.assay_type, qc_result.assay_version]
        end
    end

    context 'with a tube of a sample with a concentration' do
      let(:labware) { [tube('SAPIO-1', sample(concentration: 4.2))] }

      it 'records the concentration as a customer-supplied QC result on ' \
         'the tube' do
        expect(concentration_results).to eq(
          [[created.receptacle.id, '4.2', 'ng/ul', 'customer_supplied',
            'v0.0']]
        )
      end

      it 'leaves the concentration of the tube unset, as a tube keeps ' \
         'only molar concentrations' do
        expect(created.receptacle.reload.concentration).to be_nil
      end
    end

    context 'with a plate of samples with concentrations' do
      let(:labware) do
        [plate('SAPIO-1', sample(concentration: 4.2),
               sample(concentration: 15.5))]
      end

      it 'sets the concentration of each well' do
        expect(created.wells.located_at(%w[A1 B1]).map do |well|
          well.reload.well_attribute.concentration
        end).to eq([4.2, 15.5])
      end
    end

    context 'with a tube of a sample with a volume and a concentration' do
      let(:labware) do
        [tube('SAPIO-1', sample(volume: 12.5, concentration: 4.2))]
      end
      let(:qc_assay) do
        QcAssay.find_by!(lot_number: "api_operation_id:#{api_operation.id}")
      end

      it 'puts both QC results in the QC assay named after the operation' do
        expect(created.receptacle.qc_results.map { [it.key, it.qc_assay] })
          .to contain_exactly(['volume', qc_assay], ['concentration', qc_assay])
      end
    end

    context 'with a tube of samples with concentrations' do
      let(:labware) do
        [tube('SAPIO-1', sample(concentration: 4.2),
              sample(concentration: 3.8))]
      end

      it 'records no QC result, as the concentrations are of the samples' do
        expect(concentration_results).to be_empty
      end

      it 'keeps each concentration in its sample' do
        expect(created.receptacle.samples.map do |created_sample|
          created_sample.sample_metadata.concentration
        end).to contain_exactly('4.2', '3.8')
      end
    end

    context 'with a tube of a sample with a volume but no concentration' do
      let(:labware) { [tube('SAPIO-1', sample(volume: 12.5))] }

      it 'records no concentration QC result' do
        expect(concentration_results).to be_empty
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

      it 'gives them their positions as tag depths, counting from 1' do
        expect(created.receptacle.aliquots.map do |aliquot|
          [aliquot.sample.sanger_sample_id, aliquot.tag_depth]
        end).to contain_exactly(['SAMPLE-1', 1], ['SAMPLE-2', 2],
                                ['SAMPLE-3', 3])
      end

      it 'gives them no library' do
        expect(created.receptacle.aliquots.map(&:library))
          .to eq([nil, nil, nil])
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
          library: created.receptacle, tag_depth: 1
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
          tag2: tag_set.tag2_group.tags.find_by(map_id: 2), tag_depth: 1
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
          [aliquot.tag.map_id, aliquot.tag2, aliquot.receptacle.map_description,
           aliquot.tag_depth]
        end).to match_array(chromium.map_ids(2).map { [it, nil, 'A1', 1] })
      end
    end

    describe 'with i7 and i5 oligos' do
      let(:magic_tag_group) { TagGroup.find_by!(name: 'Magic Tag Group') }

      context 'when the Magic Tag Group has none of them' do
        let(:labware) do
          [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                  i7: 'ACGTACGT', i5: 'TTGGCCAA'))]
        end

        it 'gives the aliquot new tags in the group, with the oligos' do
          aliquot = created_sample.aliquots.sole
          expect([aliquot.tag, aliquot.tag2].map { [it.tag_group, it.oligo] })
            .to eq([[magic_tag_group, 'ACGTACGT'],
                    [magic_tag_group, 'TTGGCCAA']])
        end

        it 'numbers the new tags from 1' do
          expect(magic_tag_group.tags.pluck(:map_id)).to contain_exactly(1, 2)
        end

        it 'gives the aliquot the default tag depth' do
          expect(created_sample.aliquots.sole.tag_depth).to eq(1)
        end
      end

      context 'when the Magic Tag Group has other tags' do
        let(:other_tag) do
          create(:tag, oligo: 'GGGGGGGG', map_id: 1,
                       tag_group: create(:tag_group, name: 'Magic Tag Group'))
        end
        let(:labware) do
          other_tag # in the group before the payload's tags are created
          [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                  i7: 'ACGTACGT', i5: 'TTGGCCAA'))]
        end

        it 'numbers the new tags on from the group' do
          expect(magic_tag_group.tags.where.not(id: other_tag).pluck(:map_id))
            .to contain_exactly(2, 3)
        end
      end

      context 'when the Magic Tag Group has one, in another case' do
        let(:existing) do
          create(:tag, oligo: 'ACGTACGT', map_id: 1,
                       tag_group: create(:tag_group, name: 'Magic Tag Group'))
        end
        let(:labware) do
          [tube('SAPIO-1', sample(sanger_sample_id: 'SAMPLE-1',
                                  i7: existing.oligo.downcase))]
        end

        it 'gives the aliquot that tag' do
          expect(created_sample.aliquots.sole.tag).to eq(existing)
        end

        it 'adds no tag' do
          expect(magic_tag_group.tags.count).to eq(1)
        end
      end

      context 'when two samples give the same new oligo' do
        let(:labware) do
          [tube('SAPIO-1',
                sample(sanger_sample_id: 'SAMPLE-1', i7: 'AAAA', i5: 'GGGG'),
                sample(sanger_sample_id: 'SAMPLE-2', i7: 'CCCC', i5: 'GGGG'))]
        end

        it 'creates its tag once, for both aliquots' do
          tag = magic_tag_group.tags.where(oligo: 'GGGG').sole
          expect(created.receptacle.aliquots.map(&:tag2)).to eq([tag, tag])
        end
      end
    end
  end
end
