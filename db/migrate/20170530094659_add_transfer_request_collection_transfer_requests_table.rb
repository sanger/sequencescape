# Rails migration
class AddTransferRequestCollectionTransferRequestsTable < ActiveRecord::Migration
  def change
    create_table 'transfer_request_collection_transfer_requests' do |t|
      t.references :transfer_request_collection, foreign_key: true
      t.references :transfer_request
      t.timestamps null: false
    end
    add_foreign_key 'transfer_request_collection_transfer_requests', 'requests', column: 'transfer_request_id'
  end
end
