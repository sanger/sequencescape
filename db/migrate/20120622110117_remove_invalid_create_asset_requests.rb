class RemoveInvalidCreateAssetRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      say "Removing create asset requests for wells on non-stock plates"
      execute  <<-SQL
        DELETE
        FROM `requests`
        LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id` AND `assets`.sti_type = 'Well'
        LEFT OUTER JOIN `container_associations` ON `content_id` = `assets`.`id`
        LEFT OUTER JOIN `assets` AS plate ON `container_id` = plate.id
        LEFT OUTER JOIN `plate_purposes` ON `plate_purposes`.id = plate.plate_purpose_id
        WHERE `requests`.sti_type = 'CreateAssetRequest' AND `plate_purposes`.name != 'Stock Plate';
      SQL
    end
  end

  def self.down
  end
end
