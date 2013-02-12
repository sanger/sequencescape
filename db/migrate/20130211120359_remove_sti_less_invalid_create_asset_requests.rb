class RemoveStiLessInvalidCreateAssetRequests < ActiveRecord::Migration
  def self.up
    Request.find_in_batches(
    :joins => 'LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id`',
    :conditions => {
      :request_type_id => RequestType.find_by_key('create_asset').id,
      :assets => {:sti_type => [
        'Plate','ControlPlate','GelDilutionPlate','PicoAssayAPlate',
        'PicoAssayBPlate','PicoDilutionPlate','SequenomQcPlate','WorkingDilutionPlate'
        ]
      }
    }) do |request_batch|
      ActiveRecord::Base.transaction do
        request_batch.each do |request|
          request.destroy
        end
      end
    end

    #4381.9800s

  end

  def self.down
  end
end
