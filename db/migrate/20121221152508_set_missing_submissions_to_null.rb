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
