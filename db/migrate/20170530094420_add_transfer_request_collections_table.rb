# Rails migration
class AddTransferRequestCollectionsTable < ActiveRecord::Migration
  def change
    create_table 'transfer_request_collections' do |t|
      t.references :user, foreign_key: true
      t.timestamps null: false
    end
  end
end
