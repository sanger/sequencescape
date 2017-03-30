class RemovePlatePurposeColumnFromPlateCreators < ActiveRecord::Migration
  class PlateCreators < ActiveRecord::Base
    self.table_name = 'plate_creators'
  end

  class PlatePurpose < ActiveRecord::Base
    self.table_name = 'plate_purposes'
  end

  def up
    remove_column :plate_creators, :plate_purpose_id, :integer, null: false
  end

  def down
    add_column :plate_creators, :plate_purpose_id, :integer
    ActiveRecord::Base.transaction do
      PlateCreators.find_each do |pc|
        pc.update_attributes!(plate_purpose_id: PlatePurpose.find_by!(name: pc.name).id)
      end
    end
    change_column :plate_creators, :plate_purpose_id, :integer, null: false
  end
end
