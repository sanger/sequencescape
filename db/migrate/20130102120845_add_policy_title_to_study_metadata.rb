class AddPolicyTitleToStudyMetadata < ActiveRecord::Migration
  def self.up
    # No constraints, as not all studies need a policy title
    # Also, even those that do, the already accessioned ones will
    # be missing titles.
    add_column :study_metadata, :dac_policy_title, :string
  end

  def self.down
    remove_column :study_metadata, :dac_policy_title
  end
end
