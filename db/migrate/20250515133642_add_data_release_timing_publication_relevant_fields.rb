# frozen_string_literal: true
class AddDataReleaseTimingPublicationRelevantFields < ActiveRecord::Migration[7.1]
  def change
    add_column :study_metadata, :data_release_timing_publication_comment, :string, default: nil
    add_column :study_metadata, :data_share_in_preprint, :string, default: nil
  end
end
