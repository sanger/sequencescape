# frozen_string_literal: true
require "bunny"

# Combine the samples from a Pool XP tube into a compound sample, generate a bioscan-pool-xp-tube-to-traction message
# and submit it to RabbitMQ so that it can forwarded to Traction by the message processor.
ExportPoolXpToTractionJob =
  Struct.new(:barcode) do
    def perform
      conn = Bunny.new(connection_params)
      conn.start
      channel = conn.create_channel
      exchange = channel.headers(configatron.amqp.isg.exchange)
      exchange.publish('Test message', headers: { 'subject' => 'bioscan-pool-xp-tube-to-traction' }, persistent: true)
      puts "Published"
      conn.close
    end

    def connection_params
      connection_params = {
        host: configatron.amqp.isg.host,
        username: configatron.amqp.isg.username,
        password: configatron.amqp.isg.password,
        vhost: configatron.amqp.isg.vhost,
      }

      add_tls_params(connection_params) if configatron.amqp.isg.tls
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
