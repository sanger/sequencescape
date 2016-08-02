#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class SetMissingSubmissionsToNull < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      # Request.scoped(:joins =>['LEFT OUTER JOIN submissions ON submissions.id = submission_id'], :conditions=>{:state=>['canceled','failed'], :submissions=>{:id=>nil}}).update_all(:submission_id => nil)
      # Gah, update all ignores joins

      execute(%Q{
        UPDATE `requests`
        LEFT OUTER JOIN `submissions` ON `submissions`.`id` = `submission_id` AND `submission_id` IS NOT NULL
        SET `submission_id` = NULL
        WHERE `requests`.`state` IN ('cancelled','failed') AND `submissions`.`id` IS NULL AND `submission_id` IS NOT NULL;
        })
    end
  end

  def self.down
  end
end
