class UpdateExistingEthicalApprovalEntries < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = 'Yes'
        WHERE (ethically_approved = 1 )
          AND (study_metadata.contaminated_human_dna = 'No'
            AND study_metadata.contains_human_dna = 'Yes'
            AND study_metadata.commercially_available = 'No');
      SQL
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = 'No'
        WHERE (ethically_approved = 0 )
          AND (study_metadata.contaminated_human_dna = 'No'
            AND study_metadata.contains_human_dna = 'Yes'
            AND study_metadata.commercially_available = 'No');
      SQL
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = 'N/A'
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
        SET `ethically_approved` = true
        WHERE (ethically_approved = 'Yes' )
          AND (study_metadata.contaminated_human_dna = 'No'
            AND study_metadata.contains_human_dna = 'Yes'
            AND study_metadata.commercially_available = 'No');
      SQL
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = false
        WHERE (ethically_approved = 'No' )
          AND (study_metadata.contaminated_human_dna = 'No'
            AND study_metadata.contains_human_dna = 'Yes'
            AND study_metadata.commercially_available = 'No');
      SQL
      execute <<-SQL
        UPDATE `studies`
        INNER JOIN study_metadata
          ON study_metadata.study_id = studies.id
        SET `ethically_approved` = false
        WHERE (study_metadata.contaminated_human_dna != 'No'
            OR study_metadata.contains_human_dna != 'Yes'
            OR study_metadata.commercially_available != 'No');
      SQL
    end
  end
end
