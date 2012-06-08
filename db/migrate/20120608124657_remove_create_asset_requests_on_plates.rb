class RemoveCreateAssetRequestsOnPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      execute <<-SQL
      DELETE `requests`
        FROM `requests`
        LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id`
        WHERE `requests`.sti_type = 'CreateAssetRequest'
          AND `assets`.`sti_type` IN ('Plate','ControlPlate','GelDilutionPlate','PicoAssayAPlate','PicoAssayBPlate','PicoDilutionPlate','SequenomQcPlate','WorkingDilutionPlate');
      SQL

    end
  end

  def self.down
  end
end
