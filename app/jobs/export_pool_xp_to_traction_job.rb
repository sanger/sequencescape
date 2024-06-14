# frozen_string_literal: true

# Combine the samples from a Pool XP tube into a compound sample, generate a bioscan-pool-xp-tube-to-traction message
# and submit it to RabbitMQ so that it can forwarded to Traction by the message processor.
ExportPoolXpToTractionJob =
  Struct.new(:barcode) do
    def perform
      subject_obj = configatron.amqp.schemas.subjects[:export_pool_xp_to_traction]
      subject = subject_obj[:subject]
      version = subject_obj[:version]

      get_message_schema(subject, version)
      send_message(barcode, subject)
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

    def get_message_schema(subject, version)
      response = fetch("#{configatron.amqp.schemas.registry_url}#{subject}/versions/#{version}")
      resp_json = JSON.parse(response.body)
      resp_json['schema']
    end

    def send_message(message, subject)
      conn = Bunny.new(connection_params)
      conn.start

      begin
        channel = conn.create_channel
        exchange = channel.headers(configatron.amqp.isg.exchange, passive: true)
        exchange.publish(message, headers: { 'subject' => subject }, persistent: true)
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
