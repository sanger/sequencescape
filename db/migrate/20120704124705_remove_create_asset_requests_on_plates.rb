#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RemoveCreateAssetRequestsOnPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      CreateAssetRequest.find_each(
      :joins => 'LEFT OUTER JOIN `assets` ON `assets`.id = `requests`.`asset_id`',
      :conditions => {
        :sti_type => 'CreateAssetRequest',
        :assets => {:sti_type => [
          'Plate','ControlPlate','GelDilutionPlate','PicoAssayAPlate',
          'PicoAssayBPlate','PicoDilutionPlate','SequenomQcPlate','WorkingDilutionPlate'
          ]
        }
      }) do |request|
        request.destroy
      end
      #(2154.6816s)

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
