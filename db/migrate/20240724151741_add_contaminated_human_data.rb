class AddContaminatedHumanData < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :contaminated_human_data_access_group, :string, default: nil
  end
end
