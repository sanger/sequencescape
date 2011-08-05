class EnsurePulldownRequestTypesAreMultiplexed < ActiveRecord::Migration
  PULLDOWN_REQUEST_TYPES = [
    'Pulldown WGS',
    'Pulldown SC',
    'Pulldown ISC'
  ]

  def self.up
    RequestType.transaction do
      RequestType.update_all('for_multiplexing=TRUE', [ 'name IN (?)', PULLDOWN_REQUEST_TYPES ])
    end
  end

  def self.down
    # Do nothing
  end
end
