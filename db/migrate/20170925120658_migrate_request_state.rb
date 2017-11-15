class MigrateRequestState < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.transaction do
      WorkOrder.includes(:requests).find_each do |work_order|
        state = work_order.requests.first.state
        work_order.update_attributes!(state: state)
      end
    end
  end
end
