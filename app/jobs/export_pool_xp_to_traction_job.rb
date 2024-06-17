# frozen_string_literal: true

# Combine the samples from a Pool XP tube into a compound sample, generate a bioscan-pool-xp-tube-to-traction message
# and submit it to RabbitMQ so that it can forwarded to Traction by the message processor.
ExportPoolXpToTractionJob =
  Struct.new(:barcode) do
    def perform
      message_data = get_message_data(barcode)

      subject_obj = configatron.amqp.schemas.subjects[:export_pool_xp_to_traction]
      subject = subject_obj[:subject]
      version = subject_obj[:version]

      schema = get_message_schema(subject, version)
      encoded_message = avro_encode_message(message_data, schema)
      send_message(encoded_message, subject, version)
    end

    def fetch(uri_str, limit = 10)
      raise IOError, 'Too many HTTP redirects' if limit.zero?

      response = Net::HTTP.get_response(URI.parse(uri_str))

      case response
        when Net::HTTPSuccess     then response
        when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
      end
    end

    def get_message_data(barcode)
      {
        messageUuid: "f1b3b3b4-4b3b-4b3b-4b3b-4b3b3b3b3b3b",
        messageCreateDateUtc: 1610611200000,
        tubeBarcode: barcode,
        library: {
          volume: 110.2,
          concentration: 1.17,
          boxBarcode: "034451102141700063024"
        },
        request: {
          costCode: "S10500",
          libraryType: "Pacbio_Amplicon",
          studyUuid: "b58a81f4-8e4f-11ec-b919-fa163eea3084"
        },
        sample: {
          sampleName: "BIOSCAN123456",
          sampleUuid: "f1b3b3b4-4b3b-4b3b-4b3b-4b3b3b3b3b3b",
          speciesName: "Unidentified"
        }
      }
    end

    def get_message_schema(subject, version)
      response = fetch("#{configatron.amqp.schemas.registry_url}#{subject}/versions/#{version}")
      resp_json = JSON.parse(response.body)
      resp_json['schema']
    end

    def avro_encode_message(message, schema)
      schema = Avro::Schema.parse(schema)
      stream = StringIO.new
      writer = Avro::IO::DatumWriter.new(schema)
      encoder = Avro::IO::BinaryEncoder.new(stream)
      encoder.write("\xC3\x01") # Avro single-object container file header
      encoder.write([schema.crc_64_avro_fingerprint].pack('Q')) # 8 byte schema fingerprint
      writer.write(message, encoder)
      stream.string
    end

    def send_message(message, subject, version)
      conn = Bunny.new(connection_params)
      conn.start

      begin
        channel = conn.create_channel
        exchange = channel.headers(configatron.amqp.isg.exchange, passive: true)
        headers = { subject: subject, version: version, encoder_type: 'binary' }
        exchange.publish(message, headers: headers, persistent: true)
      ensure
        conn.close
      end
    end

    def connection_params
      connection_params = {
        host: configatron.amqp.isg.host,
        username: configatron.amqp.isg.username,
        password: configatron.amqp.isg.password,
        vhost: configatron.amqp.isg.vhost,
      }

      if configatron.amqp.isg.tls
        add_tls_params(connection_params)
      else
        connection_params
      end
    end

    def add_tls_params(connection_params)
      connection_params[:tls] = true

      begin
        connection_params[:tls_ca_certificates] = [configatron.amqp.isg.ca_certificate!]
      rescue Configatron::UndefinedKeyError
        # Should not be the case in production!
        connection_params[:verify_peer] = false
      end

      connection_params
    end
  end
