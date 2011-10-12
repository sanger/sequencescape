class SetIsAssayTypeForDataReleaseStudyTypes < ActiveRecord::Migration
  class DataReleaseStudyType < ActiveRecord::Base
    set_table_name('data_release_study_types')

    def self.set_to(state)
      DataReleaseStudyType.update_all(
        "is_assay_type = #{state.inspect.upcase}",
        [ 'name IN (?)', [ 'other sequencing-based assay', 'transcriptomics' ] ]
      )
    end
  end

  def self.up
    DataReleaseStudyType.set_to(true)
  end

  def self.down
    DataReleaseStudyType.set_to(false)
  end
end
