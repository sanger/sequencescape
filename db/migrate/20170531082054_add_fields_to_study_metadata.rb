# Rails migration
class AddFieldsToStudyMetadata < ActiveRecord::Migration
  def change
    add_column :study_metadata, :s3_email_list, :string
    add_column :study_metadata, :data_deletion_period, :string
  end
end
