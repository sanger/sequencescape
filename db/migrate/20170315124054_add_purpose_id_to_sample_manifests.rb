# Rails migration
class AddPurposeIdToSampleManifests < ActiveRecord::Migration
  def change
    add_reference :sample_manifests, :purpose
    add_foreign_key :sample_manifests, :plate_purposes, column: :purpose_id
  end
end
