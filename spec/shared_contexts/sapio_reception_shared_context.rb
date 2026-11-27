# frozen_string_literal: true

# Sapio reception from end to end: Integration Hub posts a request to the
# Sapio operations endpoint, the operation's coordinator job runs, and the
# labware and samples the request describes are created. The endpoint takes
# the place of sample manifest uploads, so the specs that include this
# context (spec/requests/api/v2/sapio/reception) follow the kinds of
# manifest. The payloads have made-up values, in the shapes manifests have;
# comments say where a manifest upload gives something different.
#
# This context gives them the study, Integration Hub's API application, the
# payload builders and post_and_process.
shared_context 'with Sapio reception' do
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
end
