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
