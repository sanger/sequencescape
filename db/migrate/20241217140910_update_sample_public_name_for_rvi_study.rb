class UpdateSamplePublicNameForRviStudy < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.connection.execute('SET autocommit = 0')
    ActiveRecord::Base.connection.execute(<<~SQLQUERY)

    UPDATE sample_metadata
    JOIN samples ON sample_metadata.sample_id = samples.id
    JOIN study_samples ON sample_metadata.sample_id = study_samples.sample_id
    JOIN studies ON study_samples.study_id = studies.id
    SET sample_metadata.sample_public_name = samples.sanger_sample_id
    WHERE studies.name = 'RVI Program - Bait Capture' AND sanger_sample_id LIKE 'RVI%';
    SQLQUERY

    ActiveRecord::Base.connection.execute('COMMIT')
    ActiveRecord::Base.connection.execute('SET autocommit = 1')
  end
end
