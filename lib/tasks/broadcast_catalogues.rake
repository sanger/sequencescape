require 'bunny'

namespace :aker do
  desc 'Broadcast a catalogue and all of its data.'
  task broadcast_catalogues: [:environment] do
    conn = Bunny.new(Rails.configuration.aker['bunny'])
    conn.start
    ch = conn.create_channel
    q = ch.queue
    Aker::Catalogue.all.each do |catalogue|
      q.publish(catalogue.to_json)
      puts "[x] #{catalogue.id}"
    end
    conn.close
  end
end
