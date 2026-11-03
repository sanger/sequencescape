# frozen_string_literal: true

require 'rails_helper'

# Sapio reception from end to end: Integration Hub posts a request to the
# Sapio operations endpoint, the operation's coordinator job runs, and the
# labware and samples the request describes are created. The endpoint takes
# the place of sample manifest uploads, so the cases follow the kinds of
# manifest. The payloads have made-up values, in the shapes manifests have;
# comments say where a manifest upload gives something different.
describe 'Sapio reception', :sapio_operations_endpoint_enabled,
         :sapio_reception_enabled do
  let(:integration_hub) do
    create(:api_application, name: ApiApplication::INTEGRATION_HUB_NAME)
  end
  # Sapio creates its studies through the Sapio studies endpoint, which
  # makes them externally managed
  let(:study) { create(:study, externally_managed: true) }

  # A request for the reception of the given labware, e.g.
  #   { request: { external_id: '4e84...', # a new UUID, unique for each request
  #                request_type: 'reception_and_work_order',
  #                schema_version: '1' },
  #     labware: [plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1'))] }
  def reception_request(*labware)
    { request: { external_id: SecureRandom.uuid,
                 request_type: 'reception_and_work_order',
                 schema_version: '1' },
      labware: labware }
  end

  # A payload sample of the study, with a donor ID, as almost every manifest
  # sample has, and the other fields given. For example,
  # sample('SAPIO-1-1', reference_genome: 'Genus species (v1)') gives
  #   { uuid: '5d93...', study_uuid: '4053...', # the study's UUID
  #     sanger_sample_id: 'SAPIO-1-1',
  #     supplier_sample_name: 'Supplier SAPIO-1-1',
  #     donor_id: 'Donor SAPIO-1-1', reference_genome: 'Genus species (v1)' }
  def sample(sanger_sample_id, **fields)
    { uuid: SecureRandom.uuid, study_uuid: study.uuid,
      sanger_sample_id: sanger_sample_id,
      supplier_sample_name: "Supplier #{sanger_sample_id}",
      donor_id: "Donor #{sanger_sample_id}" }.merge(fields)
  end

  # A payload 96-well plate with one sample in each given well. For example,
  # plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1')) gives
  #   { uuid: 'fd2f...', barcode: 'SAPIO-PLATE-1', type: 'plate96',
  #     receptacles: [{ position: 'A1', uuid: '9a51...',
  #                     samples: [sample('SAPIO-1-1')] }] }
  def plate(barcode, samples_by_well)
    receptacles = samples_by_well.map do |well, sample|
      { position: well, uuid: SecureRandom.uuid, samples: [sample] }
    end
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles }
  end

  # Posts the request as Integration Hub, then runs the coordinator job it
  # queues, as a Delayed Job worker would.
  #
  # @return [ApiOperation] the request's operation
  def post_and_process(request)
    post_as_integration_hub(request)
    work_off_jobs
    ApiOperation.find_by!(external_id: request.dig(:request, :external_id))
  end

  # Posts the request to the Sapio operations endpoint with Integration
  # Hub's API key, and raises unless it is accepted
  def post_as_integration_hub(request)
    post '/api/v2/sapio/operations',
         params: request.to_json,
         headers: { 'CONTENT_TYPE' => 'application/json',
                    'X-Sequencescape-Client-Id' => integration_hub.key }
    message = "Request not accepted: #{response.status} #{response.body}"
    raise message unless response.accepted?
  end

  # Runs the queued jobs, as a Delayed Job worker would. work_off doesn't
  # raise when a job fails: it records the error on the job and reschedules
  # it, then returns the numbers of jobs that succeeded and failed. Raising
  # here shows the job's error, instead of the examples failing later on a
  # status still queued.
  def work_off_jobs
    _successes, failures = Delayed::Worker.new.work_off
    raise "Job failed: #{Delayed::Job.last&.last_error}" if failures.positive?
  end

  # As from a plate manifest: a stock plate of samples without tags, some
  # wells left empty
  context 'with a plate of samples without tags' do
    let(:reference_genome) do
      create(:reference_genome, name: 'Genus species (v1)')
    end
    let(:samples_by_well) do
      { 'A1' => sample('SAPIO-1-1', reference_genome: reference_genome.name),
        'B1' => sample('SAPIO-1-2'),
        'C1' => sample('SAPIO-1-3', control_type: 'negative') }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               samples_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }
    let(:samples) do
      sanger_sample_ids = samples_by_well.values.pluck(:sanger_sample_id)
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
      end).to match_array(samples_by_well.values.map do |payload_sample|
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
end
