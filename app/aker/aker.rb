##
# Aker namespace - This should hold all things Aker.
module Aker
  ##
  # All Aker tables need to be prefixed with Aker.
  # This method will automatically included as long as they are namespaced.
  def self.table_name_prefix
    'aker_'
  end

  def self.broadcast_catalogue(catalogue)
    config = Rails.configuration.aker['bunny']
    if config['broadcast']
      conn = Bunny.new(config)
      conn.start
      ch = conn.create_channel
      q = ch.queue
      q.publish(catalogue)
      puts "[x] #{catalogue}"
      conn.close
    end
  end
end
