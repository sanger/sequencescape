#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class BackfillAliquotStudyId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute %Q{
    UPDATE aliquots al
    JOIN requests r ON (r.asset_id = al.receptacle_id)
    SET al.study_id = r.initial_study_id
    WHERE al.study_id IS NULL
    }
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
