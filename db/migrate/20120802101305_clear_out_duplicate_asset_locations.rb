class ClearOutDuplicateAssetLocations < ActiveRecord::Migration
  class LocationAssociation < ActiveRecord::Base
    set_table_name('location_associations')
    named_scope :for_asset, lambda { |x| { :conditions => { :locatable_id => details['locatable_id'] } } }

    def self.duplicated(&block)
      connection.select_all("SELECT locatable_id, COUNT(*) AS total FROM location_associations GROUP BY locatable_id HAVING total > 1").each do |details|
        yield(LocationAssociation.for_asset(details['locatable_id']).all)
      end
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      LocationAssociation.duplicated do |locations|
        locations.pop             # Remove what is, in theory, the last location
        locations.map(&:destroy)  # Destroy all of the others
      end
    end
  end

  def self.down
    # Nothing to do here
  end
end
