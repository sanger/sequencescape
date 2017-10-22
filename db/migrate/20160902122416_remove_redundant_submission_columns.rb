class RemoveRedundantSubmissionColumns < ActiveRecord::Migration
  def up
    remove_column :submissions, 'study_id_to_delete'
    remove_column :submissions, 'workflow_id_to_delete'
    remove_column :submissions, 'item_options_to_delete'
    remove_column :submissions, 'comments_to_delete'
    remove_column :submissions, 'project_id_to_delete'
    remove_column :submissions, 'sti_type_to_delete'
    remove_column :submissions, 'template_name_to_delete'
    remove_column :submissions, 'asset_group_id_to_delete'
    remove_column :submissions, 'asset_group_name_to_delete'
  end

  def down
    add_column :submissions, 'study_id_to_delete',         :integer
    add_column :submissions, 'workflow_id_to_delete',      :integer
    add_column :submissions, 'item_options_to_delete',     :text
    add_column :submissions, 'comments_to_delete',         :text
    add_column :submissions, 'project_id_to_delete',       :integer
    add_column :submissions, 'sti_type_to_delete',         :string
    add_column :submissions, 'template_name_to_delete',    :string
    add_column :submissions, 'asset_group_id_to_delete',   :integer
    add_column :submissions, 'asset_group_name_to_delete', :string
  end
end
