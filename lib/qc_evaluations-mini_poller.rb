#!/usr/bin/env ruby
#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require File.dirname(__FILE__) + "/../config/environment"# unless defined?(Rails.root)
#require 'activemessaging'

script_name = File.split(__FILE__).last
$0 = script_name.chomp(".rb") if $0.include?("script/runner")

A13G_CONF = ActiveMessaging::Gateway::load_connection_configuration
A13G_QUEUE_NAME = ActiveMessaging::Gateway::subscriptions["qc_evaluations_processor:qc_evaluations"].destination.value
# conf => {:reconnectDelay=>5, :host=>"localhost", :login=>"", :port=>61613, :adapter=>:stomp, :reliable=>true, :passcode=>""}
stomp_client = Stomp::Client.new(
  A13G_CONF[:login],
  A13G_CONF[:passcode],
  A13G_CONF[:host],
  A13G_CONF[:port],
  A13G_CONF[:reliable]
)

# Require client to explicitly acknowledge
stomp_headers = {
  :ack => "client",
  "activemq.prefetchSize" => 1,
  "activemq.exclusive" => true,
}

puts "Subscription: '#{A13G_QUEUE_NAME}'"
nr_messages = 0
stomp_client.subscribe A13G_QUEUE_NAME, stomp_headers do |msg|
  # processor thread:
  #  content in msg.body,
  #  stomp_client.acknowledge(msg) on success,
  #  stomp_client.unreceive(msg) for DLQ
  begin
    # pp msg.body
    doc = Hash.from_xml(msg.body)
    Batch.qc_evaluations_update(doc["evaluations"])
    stomp_client.acknowledge(msg)
    Rails.logger.silence(Logger::INFO) do
      Rails.logger.warn("Processed OK, #{doc['evaluations']['evaluation'].length} QC evaluations.", script_name)
    end
  rescue ActiveRecord::StatementInvalid, Mysql::Error => e
    Rails.logger.warn("#{e.message} -- will keep on trying...", script_name)
    sleep 10 # to allow the DBMS to come back (might just be restarting or whatever)
    begin
      ActiveRecord::Base.verify_active_connections!
      Rails.logger.warn("Reconnected to DBMS.", script_name)
      retry
    rescue => e
      Rails.logger.error("#{e.message} -- failed to reconnect DB, sorry, giving up.", script_name)
      raise
    end
  rescue NoMethodError => e
    Rails.logger.warn("Failed to parse message (#{msg.body.length} bytes), skipping: #{msg.body} --- #{e.message} (#{e.backtrace[0]})", script_name)
    #stomp_client.acknowledge(msg)
    stomp_client.unreceive(msg)
  rescue => e
    Rails.logger.warn("Error, rejecting message #{e.message}", script_name)
    stomp_client.unreceive(msg)
  end
  # if( (nr_messages += 1) > 100 )
  #   Rails.logger.info("Clean exit after #{nr_messages - 1} messages.", script_name)
  #   Thread.exit
  # end
end
stomp_client.join
stomp_client.close
