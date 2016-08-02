#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class SetIsAssayTypeForDataReleaseStudyTypes < ActiveRecord::Migration
  class DataReleaseStudyType < ActiveRecord::Base
    self.table_name =('data_release_study_types')

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
