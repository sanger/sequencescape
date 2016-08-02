#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class MakeGenotypingDefaultStudyType < ActiveRecord::Migration
  class DataReleaseStudyType < ActiveRecord::Base
    self.table_name =('data_release_study_types')
  end

  def self.up
    DataReleaseStudyType.update_all('is_default=TRUE', [ 'name=?', 'genotyping or cytogenetics' ])
  end

  def self.down
    # Nothing to do really.
  end
end
