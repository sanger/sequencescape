#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class RemoveNotSpecifiedFromDataReleaseStudyTypes < ActiveRecord::Migration
  class DataReleaseStudyType < ActiveRecord::Base
    self.table_name =('data_release_study_types')

    def self.default
      self.first(:conditions => { :is_default => true })
    end
  end

  class StudyMetadata < ActiveRecord::Base
    self.table_name =('study_metadata')
  end

  def self.up
    ActiveRecord::Base.transaction do
      # Find the two data release study types: one that we'll be removing, the other that we'll use as it's replacement
      remove_this = DataReleaseStudyType.find_by_name('not specified') or raise StandardError, "Cannot find 'not specified' data release study type"
      use_this    = DataReleaseStudyType.default                       or raise StandardError, "Cannot find the default data release study type to use"

      StudyMetadata.update_all("data_release_study_type_id=#{use_this.id}", [ 'data_release_study_type_id=?', remove_this.id ])
      remove_this.destroy
    end
  end

  def self.down
    # Do not modify the studies but do create the type
    DataReleaseStudyType.create!(:name => 'not specified')
  end
end
