#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class UpdateExistingEthicalApprovalEntries < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = NULL
        WHERE (study_metadata.contaminated_human_dna != 'No'
            OR study_metadata.contains_human_dna != 'Yes'
            OR study_metadata.commercially_available != 'No');
      SQL
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = false
        WHERE `ethically_approved` = NULL;
      SQL
    end
  end
end
