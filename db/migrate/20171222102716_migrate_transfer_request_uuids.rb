# frozen_string_literal: true

# To avoid regenerating Uuids, we migrate them to point to the new table
class MigrateTransferRequestUuids < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.transaction do
      Uuid.where(resource_type: 'Request')
          .joins('INNER JOIN transfer_requests ON transfer_requests.id = resource_id')
          .joins('LEFT OUTER JOIN requests ON requests.id = resource_id')
          .where('transfer_requests.id IS NOT NULL')
          .where('requests.id IS NULL')
          .update_all(resource_type: 'TransferRequest') # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Uuid.where(resource_type: 'TrnasferRequest')
          .update_all(resource_type: 'Request') # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
