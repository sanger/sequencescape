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

  # Create two things deployed environments have
  # - the Library Stock Plate purpose, which the record loader makes
  #   (config/default_records/plate_purposes/005_limber_purposes.yml)
  # - the name of the tag group for tags given as i7 and i5 oligos, which
  #   config/initializers/sample_manifest_excel.rb sets outside tests
  before do
    create(:input_plate_purpose, name: 'Library Stock Plate')
    allow(SampleManifestExcel.configuration)
      .to receive(:tag_group).and_return('Magic Tag Group')
  end

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

  # A payload 96-well plate with the samples in the given wells: a sample, or
  # an array of samples for a pool. For example,
  # plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1')) gives
  #   { uuid: 'fd2f...', barcode: 'SAPIO-PLATE-1', type: 'plate96',
  #     receptacles: [{ position: 'A1', uuid: '9a51...',
  #                     samples: [sample('SAPIO-1-1')] }] }
  def plate(barcode, samples_by_well)
    receptacles = samples_by_well.map do |well, samples|
      { position: well, uuid: SecureRandom.uuid,
        samples: Array.wrap(samples) }
    end
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles }
  end

  # A payload tube with the given samples. For example,
  # tube('SAPIO-TUBE-1', sample('SAPIO-1-1')) gives
  #   { uuid: '0b7e...', barcode: 'SAPIO-TUBE-1', type: 'tube',
  #     receptacles: [{ position: nil, uuid: 'c41a...',
  #                     samples: [sample('SAPIO-1-1')] }] }
  def tube(barcode, *samples)
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'tube',
      receptacles: [{ position: nil, uuid: SecureRandom.uuid,
                      samples: samples }] }
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

  # As from a Bioscan plate manifest: specimens with Bioscan supplier names,
  # and a lysate negative control in H12
  context 'with a Bioscan plate' do
    let(:payload_samples_by_well) do
      { 'A1' => sample('SAPIO-1-1', bioscan_supplier_name: 'SPECIMEN-1'),
        'B1' => sample('SAPIO-1-2', bioscan_supplier_name: 'SPECIMEN-2'),
        'H12' => sample('SAPIO-1-3', bioscan_supplier_name: 'CONTROL_LYSATE-1',
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
      end).to eq('SAPIO-1-1' => 'SPECIMEN-1', 'SAPIO-1-2' => 'SPECIMEN-2',
                 'SAPIO-1-3' => 'CONTROL_LYSATE-1')
    end

    it 'makes the sample in H12 a lysate negative control' do
      expect(samples.to_h do |sample|
        [sample.sanger_sample_id, [sample.control, sample.control_type]]
      end).to eq('SAPIO-1-1' => [false, nil], 'SAPIO-1-2' => [false, nil],
                 'SAPIO-1-3' => [true, 'lysate negative'])
    end
  end

  # As from a library plate manifest: a plate of libraries, each with an i7
  # and an i5 oligo and a library type
  context 'with a plate of libraries with i7 and i5 oligos' do
    let(:library_type) { create(:library_type) }
    let(:payload_libraries_by_well) do
      { 'A1' => sample('SAPIO-1-1', i7: 'ACGTACGT', i5: 'TTGGCCAA',
                                    library_type: library_type.name),
        'B1' => sample('SAPIO-1-2', i7: 'CATGCATG', i5: 'AACCGGTT',
                                    library_type: library_type.name),
        'C1' => sample('SAPIO-1-3', i7: 'GTCAGTCA', i5: 'GGAATTCC',
                                    library_type: library_type.name) }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    # A library plate manifest's plate is a Stock Plate unless the manifest
    # chooses another purpose, such as Library Stock Plate
    it 'creates a 96-well Library Stock Plate' do
      expect(received_plate).to have_attributes(
        class: Plate, size: 96,
        purpose: have_attributes(name: 'Library Stock Plate')
      )
    end

    it 'puts each library in its well, with its oligos as tags' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag.oligo, aliquot.tag2.oligo]
      end).to match_array(payload_libraries_by_well.map do |well, library|
        [well, library[:sanger_sample_id], library[:i7], library[:i5]]
      end)
    end

    it 'gives each aliquot the library type and its well as library' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.library_type, aliquot.library_id == aliquot.receptacle_id]
      end).to eq([[library_type.name, true]] * payload_libraries_by_well.size)
    end
  end

  # As from a library plate manifest: a plate of libraries, each with a tag
  # from a tag group by index, without a tag 2, and a library type
  context 'with a plate of libraries with tags from a tag group' do
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:library_type) { create(:library_type) }
    let(:payload_libraries_by_well) do
      %w[A1 B1 C1].each.with_index(1).to_h do |well, index|
        [well, sample("SAPIO-1-#{index}", tag_group: tag_group.name,
                                          tag_index: index,
                                          library_type: library_type.name)]
      end
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'puts each library in its well, with its tag and no tag 2' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag, aliquot.tag2_id]
      end).to match_array(payload_libraries_by_well.map do |well, library|
        [well, library[:sanger_sample_id],
         tag_group.tags.find_by(map_id: library[:tag_index]), -1]
      end)
    end
  end

  # As from a Chromium library plate manifest: a plate of libraries, each
  # with a well of a Chromium tag set's kit plate
  context 'with a plate of libraries with Chromium tags' do
    let(:chromium) { ApiOperation::Reception::Tags::Chromium }
    let(:tag_set) do
      tag_group =
        create(:tag_group_with_tags,
               tag_count: 2 * chromium::TAGS_PER_WELL,
               adapter_type: create(:adapter_type, name: 'Chromium'))
      create(:tag_set, tag_group: tag_group, tag2_group: nil)
    end
    # Each library's kit well is another library's well, so its tags can
    # only come from chromium_tag_well
    let(:payload_libraries_by_well) do
      { 'A1' => sample('SAPIO-1-1', chromium_tag_group: tag_set.name,
                                    chromium_tag_well: 'B1'),
        'B1' => sample('SAPIO-1-2', chromium_tag_group: tag_set.name,
                                    chromium_tag_well: 'A1') }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'gives each library an aliquot for each tag of its kit well' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag.map_id]
      end).to match_array(chromium.map_ids(2).map { ['A1', 'SAPIO-1-1', it] } +
                          chromium.map_ids(1).map { ['B1', 'SAPIO-1-2', it] })
    end

    it 'gives each aliquot tag depth 1 and its well as library' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.tag_depth, aliquot.library_id == aliquot.receptacle_id]
      end).to eq([[1, true]] * chromium::TAGS_PER_WELL *
                 payload_libraries_by_well.size)
    end
  end

  # As from a sample tube manifest: tubes of one sample each, without tags
  context 'with tubes of one sample each' do
    let(:payload_samples_by_tube) do
      { 'SAPIO-TUBE-1' => sample('SAPIO-1-1'),
        'SAPIO-TUBE-2' => sample('SAPIO-1-2'),
        'SAPIO-TUBE-3' => sample('SAPIO-1-3') }
    end
    let!(:operation) do
      tubes = payload_samples_by_tube.map do |barcode, sample|
        tube(barcode, sample)
      end
      post_and_process(reception_request(*tubes))
    end
    let(:received_tubes) do
      payload_samples_by_tube.keys.index_with do |barcode|
        Barcode.find_by!(barcode:).asset
      end
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Standard sample tube for each' do
      expect(received_tubes.values).to all(
        have_attributes(class: SampleTube,
                        purpose: have_attributes(name: 'Standard sample'))
      )
    end

    # A manifest's sample tube has a Sanger barcode
    it 'gives each tube only the barcode it arrived with' do
      expect(received_tubes.transform_values do |tube|
        tube.barcodes.map { [it.format, it.barcode] }
      end).to eq(payload_samples_by_tube.keys.index_with { [['external', it]] })
    end

    it 'puts each sample in its tube' do
      expect(received_tubes.transform_values do |tube|
        tube.aliquots.map { it.sample.sanger_sample_id }
      end).to eq(payload_samples_by_tube.transform_values do |payload_sample|
        [payload_sample[:sanger_sample_id]]
      end)
    end

    it 'gives each aliquot the study, no tags, tag depth 1 and no library' do
      expect(received_tubes.values.flat_map(&:aliquots).map do |aliquot|
        [aliquot.study, aliquot.tag_id, aliquot.tag2_id, aliquot.tag_depth,
         aliquot.library_id]
      end).to eq([[study, -1, -1, 1, nil]] * payload_samples_by_tube.size)
    end
  end

  # As from a multiplexed library tube manifest with tag sequences: libraries
  # in one tube, each with an i7 and an i5 oligo, without library fields
  context 'with a tube of libraries with i7 and i5 oligos' do
    let(:payload_libraries) do
      [sample('SAPIO-1-1', i7: 'ACGTACGT', i5: 'TTGGCCAA'),
       sample('SAPIO-1-2', i7: 'CATGCATG', i5: 'AACCGGTT'),
       sample('SAPIO-1-3', i7: 'GTCAGTCA', i5: 'GGAATTCC')]
    end
    let!(:operation) do
      post_and_process(reception_request(tube('SAPIO-TUBE-1',
                                              *payload_libraries)))
    end
    let(:received_tube) { Barcode.find_by!(barcode: 'SAPIO-TUBE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Standard MX tube' do
      expect(received_tube).to have_attributes(
        class: MultiplexedLibraryTube,
        purpose: have_attributes(name: 'Standard MX')
      )
    end

    # A manifest's MX tube has a Sanger barcode
    it 'gives the tube only the barcode it arrived with' do
      expect(received_tube.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-TUBE-1]])
    end

    it 'tags each library with its oligos, in the Magic Tag Group' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.sample.sanger_sample_id,
         *[aliquot.tag, aliquot.tag2].map { [it.tag_group.name, it.oligo] }]
      end).to match_array(payload_libraries.map do |library|
        [library[:sanger_sample_id], ['Magic Tag Group', library[:i7]],
         ['Magic Tag Group', library[:i5]]]
      end)
    end

    # A manifest also makes a library tube for each sample: the library of
    # the sample's aliquot in the MX tube
    # (SampleManifest::MultiplexedLibraryBehaviour)
    it 'gives each aliquot the study, tag depth 1 and the tube as library' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.study, aliquot.library, aliquot.tag_depth]
      end).to eq(
        [[study, received_tube.receptacle, 1]] * payload_libraries.size
      )
    end

    it 'creates no labware other than the tube' do
      expect(Labware.all).to contain_exactly(received_tube)
    end
  end

  # As from a multiplexed library tube manifest: libraries in one tube, each
  # with a tag and a tag 2 from tag groups by index, a library type and
  # insert sizes
  context 'with a tube of libraries with tags from tag groups' do
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:tag2_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:library_type) { create(:library_type) }
    let(:payload_libraries) do
      (1..3).map do |index|
        sample("SAPIO-1-#{index}",
               tag_group: tag_group.name, tag_index: index,
               tag2_group: tag2_group.name, tag2_index: index,
               library_type: library_type.name,
               insert_size_from: 100, insert_size_to: 200)
      end
    end
    let!(:operation) do
      post_and_process(reception_request(tube('SAPIO-TUBE-1',
                                              *payload_libraries)))
    end
    let(:received_tube) { Barcode.find_by!(barcode: 'SAPIO-TUBE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'gives each library its tags, library type and insert sizes' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.sample.sanger_sample_id, aliquot.tag, aliquot.tag2,
         aliquot.library_type, aliquot.insert_size_from,
         aliquot.insert_size_to]
      end).to match_array(payload_libraries.map do |library|
        [library[:sanger_sample_id],
         tag_group.tags.find_by(map_id: library[:tag_index]),
         tag2_group.tags.find_by(map_id: library[:tag2_index]),
         library_type.name, 100, 200]
      end)
    end
  end
end
