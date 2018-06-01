
class AddFlexibleCherrypickRequest < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name = 'request_types'
  end

  class SubmissionWorkflow < ApplicationRecord
    self.table_name = 'submission_workflows'
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(asset_type: 'Well',
                          billable: false,
                          deprecated: false,
                          for_multiplexing: false,
                          initial_state: 'pending',
                          key: 'flexible_cherrypick',
                          morphology: 0,
                          multiples_allowed: false,
                          name: 'Flexible Cherrypick',
                          no_target_asset: false,
                          order: 1,
                          request_class_name: 'PooledCherrypickRequest',
                          workflow_id: SubmissionWorkflow.find_by(name: 'Microarray genotyping').id)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by(name: 'Flexible Cherrypick').destroy
    end
  end
end
