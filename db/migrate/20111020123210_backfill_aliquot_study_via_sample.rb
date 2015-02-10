#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class BackfillAliquotStudyViaSample < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute %(
      UPDATE aliquots AS al
      JOIN study_samples AS ss
        ON (al.sample_id = ss.sample_id)
      SET al.study_id=ss.study_id
      WHERE al.study_id IS NULL;
)
    end
  end

  def self.down
  end
end
