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
