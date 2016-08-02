#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SupercedeAllHiddenSubmissionTemplates < ActiveRecord::Migration
  class SubmissionTemplate < ActiveRecord::Base
    self.table_name =('submission_templates')
    scope :hidden, -> { where( :visible => false ) }
  end

  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.hidden.update_all('superceded_by_id=-2')
    end
  end

  def self.down
    # Nothing to do here really because we'll drop through to remove them
  end
end
