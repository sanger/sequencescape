class RemoveInvalidCreateAssetRequests < ActiveRecord::Migration
  def self.up

      say "Removing create asset requests for wells on non-stock plates"

      CreateAssetRequest.find_in_batches(
      :joins => [
        'LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.asset_id',
        'LEFT OUTER JOIN `container_associations` ON `content_id` = `assets`.id',
        'LEFT OUTER JOIN `assets` AS plate ON `container_id` = plate.id',
        'LEFT OUTER JOIN `plate_purposes` ON `plate_purposes`.id = plate.plate_purpose_id'
        ],
      :conditions => "`requests`.sti_type = 'CreateAssetRequest' AND `plate_purposes`.name != 'Stock Plate' AND plate.id IS NOT NULL AND `assets`.sti_type = 'Well'"
      ) do |request_group|
        ActiveRecord::Base.transaction do
          request_group.each {|request| request.destroy }
        end
      end

  end

  def self.down
  end
end
