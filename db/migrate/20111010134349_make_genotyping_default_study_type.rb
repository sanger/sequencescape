class MakeGenotypingDefaultStudyType < ActiveRecord::Migration
  class DataReleaseStudyType < ActiveRecord::Base
    set_table_name('data_release_study_types')
  end

  def self.up
    DataReleaseStudyType.update_all('is_default=TRUE', [ 'name=?', 'genotyping or cytogenetics' ])
  end

  def self.down
    # Nothing to do really.
  end
end
