class SwitchDataReleaseStrategyFromNotApplicableToManaged < ActiveRecord::Migration
  class StudyMetadata < ActiveRecord::Base
    set_table_name('study_metadata')
  end

  def self.up
    StudyMetadata.update_all('data_release_strategy="managed"', [ 'data_release_strategy=?', 'not applicable' ])
  end

  def self.down
    # Nothing to do here
  end
end
