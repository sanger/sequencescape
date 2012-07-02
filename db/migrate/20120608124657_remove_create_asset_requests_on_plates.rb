class RemoveCreateAssetRequestsOnPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      CreateAssetRequest.find(
      :all,
      :joins => 'LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id`',
      :conditions => {
        :sti_type => 'CreateAssetRequest',
        :assets => {:sti_type => [
          'Plate','ControlPlate','GelDilutionPlate','PicoAssayAPlate',
          'PicoAssayBPlate','PicoDilutionPlate','SequenomQcPlate','WorkingDilutionPlate'
          ]
        }
      }).map(&:destroy)

      # execute <<-SQL
      # DELETE `requests`
      #   FROM `requests`
      #   LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id`
      #   WHERE `requests`.sti_type = 'CreateAssetRequest'
      #     AND `assets`.`sti_type` IN ('Plate','ControlPlate','GelDilutionPlate','PicoAssayAPlate','PicoAssayBPlate','PicoDilutionPlate','SequenomQcPlate','WorkingDilutionPlate');
      # SQL

    end
  end

  def self.down
  end
end
