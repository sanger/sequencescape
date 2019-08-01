# Some asset links were created without properly using the API, resulting in odd error
# cases we then needed to handle.
class RepairBrokeAssetLinks < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      AssetLink.where('count IS NULL').update_all(count: 1)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
