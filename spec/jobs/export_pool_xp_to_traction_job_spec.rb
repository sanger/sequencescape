# frozen_string_literal: true

RSpec.describe ExportPoolXpToTractionJob, type: :job do
  let(:export_job) { described_class.new(tube.human_barcode) }
  let(:tube) { create :multiplexed_library_tube, sample_count: 3 }

  let(:schema_subject) { 'bioscan-pool-xp-tube-to-traction' }
  let(:schema_version) { 1 }

  let(:message_data) { { key: 'value' } }
  let(:message_schema) { '{}' }

  describe '#perform' do
    let(:encoded_message) { 'encoded_message' }

    before do
      # Mock HTTP requests to the schema registry
      stub_request(:get, 'http://redpanda.uat.psd.sanger.ac.uk/subjects/bioscan-pool-xp-tube-to-traction/versions/1')
        .to_return(status: 200, body: '{"schema": "{}"}', headers: {})

      # Mock Avro message encoding
      allow(export_job).to receive_messages(get_message_data: message_data, get_message_schema: message_schema,
avro_encode_message: encoded_message)
      allow(export_job).to receive(:send_message)

      export_job.perform
    end

    it 'calls get_message_data' do
      expect(export_job).to have_received(:get_message_data).with(tube.human_barcode)
    end

    it 'calls get_message_schema' do
      expect(export_job).to have_received(:get_message_schema).with(schema_subject, schema_version)
    end

    it 'calls avro_encode_message' do
      expect(export_job).to have_received(:avro_encode_message).with(message_data, message_schema)
    end

    it 'calls send_message' do
      expect(export_job).to have_received(:send_message).with(encoded_message, schema_subject, schema_version)
    end
  end

  describe '#get_message_data' do
    let(:project) { create :project }
    let(:message_data) { export_job.get_message_data(tube.human_barcode) }
    let(:study) { create :study }
    let(:compound_sample) { create :sample }

    before do
      allow(tube).to receive_messages(projects: [project], studies: [study])
      allow(export_job).to receive(:find_or_create_compound_sample).and_return(compound_sample)
    end


    it 'returns the correct message structure' do
      expect(message_data).to include(
        messageUuid: kind_of(String),
        messageCreateDateUtc: kind_of(Time),
        tubeBarcode: tube.human_barcode,
        library: kind_of(Hash),
        request: kind_of(Hash),
        sample: kind_of(Hash)
      )
    end

    it 'returns valid library data' do
      expect(message_data[:library]).to include(
        volume: 100.0,
        concentration: 0.0,
        boxBarcode: 'Unspecified'
      )
    end

    it 'returns valid request data' do
      expect(message_data[:request]).to include(
        costCode: project.project_cost_code,
        libraryType: 'Pacbio_Amplicon',
        studyUuid: kind_of(String)
      )
    end

    it 'returns valid sample data' do
      expect(message_data[:sample]).to include(
        sampleName: compound_sample.name,
        sampleUuid: compound_sample.uuid,
        speciesName: 'Unidentified'
      )
    end
  end


  describe '#avro_encode_message' do
    let(:mock_schema) { instance_double(Avro::Schema) }
    let(:mock_datum_writer) { instance_double(Avro::IO::DatumWriter) }

    let(:encoded_message) { 'encoded_message' }

    before do
      # Mock Avro functionality
      allow(Avro::Schema).to receive(:parse).and_return(mock_schema)
      allow(Avro::IO::DatumWriter).to receive(:new).and_return(mock_datum_writer)
      allow(mock_datum_writer).to receive(:write)
      allow(mock_schema).to receive(:crc_64_avro_fingerprint).and_return(0x1234567890ABCDEF)
    end

    it 'prepends the encoded data with the format marker' do
      result = export_job.avro_encode_message(message_data, message_schema)
      expect(result[0,2]).to eq("\xC3\x01")
    end

    it 'includes any crc 64 fingerprint in the encoded data' do
      result = export_job.avro_encode_message(message_data, message_schema)
      expect(result.length).to be > 2
    end
  end

end
