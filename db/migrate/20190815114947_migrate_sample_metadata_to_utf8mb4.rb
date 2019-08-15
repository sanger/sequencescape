# frozen_string_literal: true

# StudyMetadata and SampleMetadata are the two primary sticking points when
# it comes to encoding issues, so we update them first. I'm converting the whole
# table here as no sting/text columns are indexed.
class MigrateSampleMetadataToUtf8mb4 < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute(<<~SQLQUERY
      ALTER TABLE sample_metadata CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    SQLQUERY
                                         )
  end

  def down
    ActiveRecord::Base.connection.execute(<<~SQLQUERY
      ALTER TABLE sample_metadata CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci
    SQLQUERY
                                         )
  end
end
