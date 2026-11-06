# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, as from plate manifests. How these specs
# work: spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of plates',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # As from a plate manifest: a stock plate of samples without tags, some
  # wells left empty
  context 'with a plate of samples without tags' do
    let(:reference_genome) do
      create(:reference_genome, name: 'Genus species (v1)')
    end
    let(:payload_samples_by_well) do
      { 'A1' => sample('SAPIO-1-1', reference_genome: reference_genome.name),
        'B1' => sample('SAPIO-1-2'),
        'C1' => sample('SAPIO-1-3', control_type: 'negative') }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_samples_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }
    let(:samples) do
      sanger_sample_ids =
        payload_samples_by_well.values.pluck(:sanger_sample_id)
      Sample.where(sanger_sample_id: sanger_sample_ids)
        .includes(:sample_metadata).index_by(&:sanger_sample_id)
    end
    # The reference genome a sample without one keeps: the column's default,
    # as manifest uploads leave it (a blank genome in deployed databases)
    let(:default_genome_id) do
      Sample::Metadata.column_defaults['reference_genome_id']
    end

    # Each sample's supplier name, donor ID, reference genome and control
    # fields, by Sanger sample ID
    def sample_fields
      samples.transform_values do |sample|
        metadata = sample.sample_metadata
        [metadata.supplier_name, metadata.donor_id,
         metadata.reference_genome_id, sample.control, sample.control_type]
      end
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'records the run of the reception' do
      expect(operation.events.pluck(:task, :outcome))
        .to eq([%w[reception started], %w[reception completed]])
    end

    it 'creates a 96-well Stock Plate' do
      expect(received_plate).to have_attributes(
        class: Plate, size: 96, purpose: have_attributes(name: 'Stock Plate')
      )
    end

    # A manifest's plate has a Sanger barcode from Baracoda
    it 'gives the plate only the barcode it arrived with' do
      expect(received_plate.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-PLATE-1]])
    end

    it 'puts each sample in its well, and leaves the other wells empty' do
      filled = received_plate.wells.includes(:map, aliquots: :sample)
        .select { |well| well.aliquots.any? }
      expect(filled.to_h do |well|
        [well.map.description, well.aliquots.map { it.sample.sanger_sample_id }]
      end).to eq('A1' => ['SAPIO-1-1'], 'B1' => ['SAPIO-1-2'],
                 'C1' => ['SAPIO-1-3'])
    end

    # A sample keeps its UUID from the payload, is externally managed, and
    # has no sample manifest. Manifest uploads make new UUIDs instead.
    it 'creates externally managed samples with the payload UUIDs' do
      expect(samples.values.map do |sample|
        [sample.name, sample.uuid, sample.externally_managed,
         sample.sample_manifest_id, sample.studies]
      end).to match_array(payload_samples_by_well.values.map do |payload_sample|
        [payload_sample[:sanger_sample_id], payload_sample[:uuid], true, nil,
         [study]]
      end)
    end

    it 'stores the sample fields the request gives' do
      expect(sample_fields).to eq(
        'SAPIO-1-1' => ['Supplier SAPIO-1-1', 'Donor SAPIO-1-1',
                        reference_genome.id, false, nil],
        'SAPIO-1-2' => ['Supplier SAPIO-1-2', 'Donor SAPIO-1-2',
                        default_genome_id, false, nil],
        'SAPIO-1-3' => ['Supplier SAPIO-1-3', 'Donor SAPIO-1-3',
                        default_genome_id, true, 'negative']
      )
    end

    # Untagged and alone in its well, an aliquot keeps the tag depth's
    # default, 1, as manifest uploads leave it since Y26-295 (#6134)
    it 'gives each aliquot the study, no tags and no library' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.study, aliquot.tag_id, aliquot.tag2_id, aliquot.tag_depth,
         aliquot.library_id]
      end).to eq([[study, -1, -1, 1, nil]] * 3)
    end

    # A plate manifest makes a CreateAssetRequest for each well
    # (SampleManifest::GenerateWellsJob), and its upload registers the
    # filled wells as stock (SampleManifestExcel::Upload::Base
    # #register_stock_resources). The story's design notes leave both out.
    it 'creates no asset requests and registers no stock' do
      well_ids = received_plate.wells.ids
      expect([CreateAssetRequest.where(asset_id: well_ids).count,
              Messenger.where(root: 'stock_resource').count]).to eq([0, 0])
    end
  end

  # As from a plate manifest with pools: a well holding a pool of samples
  # without tags
  context 'with a pool of samples without tags in a well' do
    let(:payload_pool) do
      %w[SAPIO-1-1 SAPIO-1-2 SAPIO-1-3 SAPIO-1-4].map { sample(it) }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_pool)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Stock Plate, as the pool has no tags' do
      expect(received_plate.purpose.name).to eq('Stock Plate')
    end

    # A manifest numbers a pool's tag depths from 0
    # (SampleManifest::CoreBehaviour::StockAssets#tag_depth_for_sample)
    it 'gives the samples tag depths by their positions, counting from 1' do
      well = received_plate.wells.located_at('A1').sole
      expect(well.aliquots.map do |aliquot|
        [aliquot.sample.sanger_sample_id, aliquot.tag_depth]
      end).to contain_exactly(['SAPIO-1-1', 1], ['SAPIO-1-2', 2],
                              ['SAPIO-1-3', 3], ['SAPIO-1-4', 4])
    end
  end

  # As from a Bioscan plate manifest: specimens named by their specimen plate
  # and well, and a lysate negative control in H12, whose name begins with
  # CONTROL_ as a control's must
  context 'with a Bioscan plate' do
    let(:payload_samples_by_well) do
      { 'A1' => sample('SAPIO-1-1', bioscan_supplier_name: 'TEST_001_A1'),
        'B1' => sample('SAPIO-1-2', bioscan_supplier_name: 'TEST_001_B1'),
        'H12' =>
          sample('SAPIO-1-3',
                 bioscan_supplier_name: 'CONTROL_NEG_LYSATE_TEST_001_H12',
                 bioscan_control_type: 'lysate negative') }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_samples_by_well)))
    end
    let(:samples) do
      Sample.where(sanger_sample_id: %w[SAPIO-1-1 SAPIO-1-2 SAPIO-1-3])
        .includes(:sample_metadata)
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    # The request needs supplier_sample_name too, which a Bioscan manifest
    # doesn't have: bioscan_supplier_name replaces it, as in the manifest
    it 'gives each sample its Bioscan supplier name' do
      expect(samples.to_h do |sample|
        [sample.sanger_sample_id, sample.sample_metadata.supplier_name]
      end).to eq('SAPIO-1-1' => 'TEST_001_A1', 'SAPIO-1-2' => 'TEST_001_B1',
                 'SAPIO-1-3' => 'CONTROL_NEG_LYSATE_TEST_001_H12')
    end

    it 'makes the sample in H12 a lysate negative control' do
      expect(samples.to_h do |sample|
        [sample.sanger_sample_id, [sample.control, sample.control_type]]
      end).to eq('SAPIO-1-1' => [false, nil], 'SAPIO-1-2' => [false, nil],
                 'SAPIO-1-3' => [true, 'lysate negative'])
    end
  end
end
