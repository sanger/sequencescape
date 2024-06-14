# frozen_string_literal: true

# Combine the samples from a Pool XP tube into a compound sample, generate a bioscan-pool-xp-tube-to-traction message
# and submit it to RabbitMQ so that it can forwarded to Traction by the message processor.
ExportPoolXpToTractionJob =
  Struct.new(:barcode) do
    def perform
      send_message(barcode, 'bioscan-pool-xp-tube-to-traction')
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
