# frozen_string_literal: true

RSpec.describe ExportPoolXpToTractionJob, type: :job do
  let(:export_job) { described_class.new(tube.human_barcode) }
  let(:tube) { create(:multiplexed_library_tube, sample_count: 3) }

  let(:schema_subject) { configatron.amqp.schemas.subjects[:export_pool_xp_to_traction][:subject] }
  let(:schema_version) { configatron.amqp.schemas.subjects[:export_pool_xp_to_traction][:version] }

  let(:message_data) { { key: 'value' } }
  let(:message_schema) { '{}' }

  describe '#perform' do
    let(:encoded_message) { 'encoded_message' }

    before do
      # Mock called methods
      allow(export_job).to receive_messages(
        get_message_data: message_data,
        get_message_schema: message_schema,
        avro_encode_message: encoded_message,
        send_message: nil
      )

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

    it 'logs an error if an exception is raised' do
      allow(export_job).to receive(:get_message_data).and_raise(ArgumentError.new('An error'))
      allow(Rails.logger).to receive(:error).and_call_original

      expect { export_job.perform }.to raise_error(ArgumentError, 'An error')
      expect(Rails.logger).to have_received(:error).with('Error exporting Pool XP tube to Traction: <An error>')
    end
  end

  describe '#get_message_data' do
    let(:project) { create(:project) }
    let(:actual_message) { export_job.get_message_data(tube.human_barcode) }
    let(:study) { create(:study) }
    let(:compound_sample) { create(:sample) }

    before do
      allow(tube).to receive_messages(projects: [project], studies: [study])
      allow(export_job).to receive(:find_or_create_compound_sample).and_return(compound_sample)
    end

    it 'returns a message with the correct values and/or types' do
      expect(actual_message).to include(
        messageUuid: kind_of(String),
        messageCreateDateUtc: kind_of(Time),
        tubeBarcode: tube.human_barcode,
        library: {
          volume: 100.0,
          concentration: 0.0,
          boxBarcode: 'Unspecified'
        },
        request: {
          costCode: project.project_cost_code,
          libraryType: 'Pacbio_Amplicon',
          studyUuid: kind_of(String)
        },
        sample: {
          sampleName: compound_sample.name,
          sampleUuid: compound_sample.uuid,
          speciesName: 'Unidentified'
        }
      )
    end

    it 'returns valid uuids for relevant fields' do
      expect(UUIDTools::UUID.parse(actual_message[:messageUuid])).to be_valid
      expect(UUIDTools::UUID.parse(actual_message[:request][:studyUuid])).to be_valid
      expect(UUIDTools::UUID.parse(actual_message[:sample][:sampleUuid])).to be_valid
    end
  end

  describe '#get_message_schema' do
    let(:cache_file_path) { "data/avro_schema_cache/#{schema_subject}_v#{schema_version}.avsc" }

    before do
      # Remove any cached schema file
      File.delete(cache_file_path) if File.exist?(cache_file_path)
    end

    context 'when the schema is cached' do
      before do
        # Create the cached schema file
        File.write(cache_file_path, message_schema)

        # Make the registry raise an error if it's called
        stub_request(
          :get,
          "http://test-redpanda/subjects/#{schema_subject}/versions/#{schema_version}"
        ).to_raise 'Should not have been called'
      end

      it 'logs that the cached file schema is being used' do
        allow(Rails.logger).to receive(:debug).and_call_original

        # Ideally we'd use .to have_received but I'm unable to make it work with block syntax.
        # rubocop:disable RSpec/MessageSpies
        expect(Rails.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("Using cached schema for #{schema_subject} v#{schema_version}")
        end
        # rubocop:enable RSpec/MessageSpies

        export_job.get_message_schema(schema_subject, schema_version)
      end

      it 'returns the cached schema' do
        expect(export_job.get_message_schema(schema_subject, schema_version)).to eq(message_schema)
      end

      it "doesn't query the registry" do
        expect { export_job.get_message_schema(schema_subject, schema_version) }.not_to raise_error
      end
    end

    context 'when the schema gets fetched from the registry' do
      before do
        # Mock HTTP requests to the schema registry
        stub_request(:get, "http://test-redpanda/subjects/#{schema_subject}/versions/#{schema_version}").to_return(
          status: 200,
          body: '{"schema": "{the_schema}"}',
          headers: {}
        )
      end

      it 'returns the schema from the schema registry' do
        expect(export_job.get_message_schema(schema_subject, schema_version)).to eq('{the_schema}')
      end

      it 'logs that the schema is being fetched and cached' do
        allow(Rails.logger).to receive(:debug).and_call_original

        # Ideally we'd use .to have_received but I'm unable to make it work with block syntax.
        # rubocop:disable RSpec/MessageSpies
        expect(Rails.logger).to receive(:debug) do |&block|
          expect(block.call).to eq("Fetching and caching schema for #{schema_subject} v#{schema_version}")
        end
        # rubocop:enable RSpec/MessageSpies

        export_job.get_message_schema(schema_subject, schema_version)
      end
    end

    context 'when the schema cannot be fetched' do
      before do
        # Mock HTTP requests to the schema registry
        stub_request(:get, "http://test-redpanda/subjects/#{schema_subject}/versions/#{schema_version}").to_return(
          status: 404,
          body: '',
          headers: {}
        )
      end

      it 'raises an error' do
        expect { export_job.get_message_schema(schema_subject, schema_version) }.to raise_error(StandardError)
      end
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
      expect(result[0, 2]).to eq("\xC3\x01")
    end

    it 'includes any crc 64 fingerprint in the encoded data' do
      result = export_job.avro_encode_message(message_data, message_schema)
      expect(result.length).to be > 2
    end
  end

  describe '#send_message' do
    let(:encoded_message) { 'encoded_message' }
    let(:mock_bunny) { instance_double(Bunny::Session, start: nil, create_channel: mock_channel, close: nil) }
    let(:mock_channel) { instance_double(Bunny::Channel, headers: mock_exchange) }
    let(:mock_exchange) { instance_double(Bunny::Exchange, publish: nil) }

    before { allow(Bunny).to receive(:new).and_return(mock_bunny) }

    it 'creates a valid connection to the AMQP broker' do
      export_job.send_message(encoded_message, schema_subject, schema_version)

      expect(Bunny).to have_received(:new).with(
        host: configatron.amqp.broker.host,
        username: configatron.amqp.broker.username,
        password: configatron.amqp.broker.password,
        vhost: configatron.amqp.broker.vhost,
        tls: true,
        tls_ca_certificates: [configatron.amqp.broker.ca_certificate]
      )
    end

    it 'sends the encoded message to the AMQP broker' do
      export_job.send_message(encoded_message, schema_subject, schema_version)

      expect(mock_exchange).to have_received(:publish).with(
        encoded_message,
        headers: {
          subject: schema_subject,
          version: schema_version,
          encoder_type: 'binary'
        },
        persistent: true
      )
    end

    it 'closes the connection after sending the message' do
      export_job.send_message(encoded_message, schema_subject, schema_version)

      expect(mock_bunny).to have_received(:close)
    end

    it 'closes the connection even if an error is raised' do
      allow(mock_exchange).to receive(:publish).and_raise('An error')

      expect { export_job.send_message(encoded_message, schema_subject, schema_version) }.to raise_error('An error')
      expect(mock_bunny).to have_received(:close)
    end
  end
end
