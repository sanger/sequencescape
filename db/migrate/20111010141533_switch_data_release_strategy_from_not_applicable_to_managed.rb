#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class SwitchDataReleaseStrategyFromNotApplicableToManaged < ActiveRecord::Migration
  class StudyMetadata < ActiveRecord::Base
    self.table_name =('study_metadata')
  end

  def self.up
    StudyMetadata.update_all('data_release_strategy="managed"', [ 'data_release_strategy=?', 'not applicable' ])
  end

  def self.down
    # Nothing to do here
  end
end
