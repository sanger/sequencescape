class AddDataReleaseTimingPublicationComment < ActiveRecord::Migration[7.1]
  def change
    add_column :study_metadata, :data_release_timing_publication_comment, :string, default: nil
  end
end
