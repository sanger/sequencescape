#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class HideNotSpecifiedStudyType < ActiveRecord::Migration
  class StudyType < ActiveRecord::Base
    self.table_name =('study_types')
  end

  def self.set_valid_for_creation_to(state)
    StudyType.update_all("valid_for_creation=#{state.to_s.upcase}", [ 'name=?', 'Not specified' ])
  end

  def self.up
    set_valid_for_creation_to(false)
  end

  def self.down
    set_valid_for_creation_to(true)
  end
end
