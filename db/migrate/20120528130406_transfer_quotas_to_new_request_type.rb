class TransferQuotasToNewRequestType < ActiveRecord::Migration

  def self.up
   ActiveRecord::Base.transaction do

     new_request_type = RequestType.find_by_key('illumina_b_std').id

     say 'Migrating quotas'
     execute %Q{
       INSERT INTO `quotas` (`limit`, project_id, request_type_id, `preordered_count`)
         SELECT (`quotas`.limit - preordered_count), project_id, #{new_request_type}, 0
         FROM `quotas`
         JOIN request_types ON quotas.request_type_id = request_types.id
         WHERE request_types.key = 'illumina_b_multiplexed_library_creation';
     }
     say 'Removing old quotas'
     execute <<-SQL
       UPDATE `quotas`
         JOIN request_types ON quotas.request_type_id = request_types.id
         SET `quotas`.limit = `quotas`.`preordered_count`
         WHERE request_types.key = 'illumina_b_multiplexed_library_creation';
     SQL
   end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say 'Moving quotas back'

      new_request_type = RequestType.find_by_key('illumina_b_std').id
      execute %Q{
        UPDATE `quotas`
          JOIN request_types ON quotas.request_type_id = request_types.id
          JOIN `quotas` AS new_quota ON quotas.project_id = new_quota.project_id AND new_quota.request_type_id =#{new_request_type}
          SET `quotas`.limit = (`quotas`.limit + new_quota.limit),
            `quotas`.preordered_count = (`quotas`.preordered_count + new_quota.preordered_count)
          WHERE request_types.key = 'illumina_b_multiplexed_library_creation';
      }
      say 'Removing new quotas'
      Quota.delete_all(:request_type_id => new_request_type)
    end
  end
end
