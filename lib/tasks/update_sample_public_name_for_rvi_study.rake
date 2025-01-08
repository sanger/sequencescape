namespace :samples do
  desc "Update sample_public_name for RVI Program - Bait Capture study"
  task update_public_name: :environment do
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

    puts "Sample public names updated successfully for RVI Program - Bait Capture study."
  end
end