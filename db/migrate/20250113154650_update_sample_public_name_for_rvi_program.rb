# frozen_string_literal: true
class UpdateSamplePublicNameForRviProgram < ActiveRecord::Migration[7.0]
  def up
    execute(<<~SQLQUERY)
      UPDATE sample_metadata
      JOIN samples ON sample_metadata.sample_id = samples.id
      JOIN study_samples ON sample_metadata.sample_id = study_samples.sample_id
      JOIN studies ON study_samples.study_id = studies.id
      SET sample_metadata.sample_public_name = samples.sanger_sample_id
      WHERE sample_metadata.sample_public_name IS NULL
      AND sanger_sample_id LIKE 'RVI%'
      AND studies.name = 'RVI Program - Bait Capture';
    SQLQUERY
  end

  def down
    execute(<<~SQLQUERY)
      UPDATE sample_metadata
      JOIN samples ON sample_metadata.sample_id = samples.id
      JOIN study_samples ON sample_metadata.sample_id = study_samples.sample_id
      JOIN studies ON study_samples.study_id = studies.id
      SET sample_metadata.sample_public_name = NULL
      WHERE sample_metadata.sample_public_name = samples.sanger_sample_id
      AND sanger_sample_id LIKE 'RVI%'
      AND studies.name = 'RVI Program - Bait Capture';
    SQLQUERY
  end
end
