# frozen_string_literal: true

# Fragment is a historic record which tracked gel fragments.
# Data was stored in the descriptors column
# This migrates the data to custom metadata to preserve it.
class MigrateHistoricDescriptorsToCustomMetadata < ActiveRecord::Migration[5.1]
  # Migration specific version of asset
  # Protects the migration against future changes in code
  class MigratingAsset < ApplicationRecord
    self.table_name = 'assets'
    serialize :descriptors, coder: YAML

    scope :fragments_with_descriptors,
          lambda { where.not(descriptors: nil).where('descriptors != "---\n"').where(sti_type: 'Fragment') }
  end

  # Migration specific version of CustomMetadataCollection
  # Protects the migration against future changes in code
  class MigratingCustomMetadatumCollection < ApplicationRecord
    self.table_name = 'custom_metadatum_collections'

    def metadata=(attributes)
      MigratingCustomMetadatum.create!(
        attributes.map { |k, v| { key: k, value: v, custom_metadatum_collection_id: id } }
      )
    end
  end

  # Migration specific version of User
  # Protects the migration against future changes in code
  class MigratingUser < ApplicationRecord
    self.table_name = 'users'
  end

  # Migration specific version of CustomMetadatum
  # Protects the migration against future changes in code
  class MigratingCustomMetadatum < ApplicationRecord
    self.table_name = 'custom_metadata'
  end

  def up
    ActiveRecord::Base.transaction do
      data_owner =
        User.find_or_create_by!(login: configatron.sequencescape_email, email: configatron.sequencescape_email)
      MigratingAsset.fragments_with_descriptors.find_each do |fragment|
        say "Fragment #{fragment.id}"
        collection = MigratingCustomMetadatumCollection.create!(user_id: data_owner.id, asset_id: fragment.id)
        collection.metadata = fragment.descriptors
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      MigratingCustomMetadatumCollection.where(asset_id: MigratingAsset.fragments_with_descriptors).destroy_all
    end
  end
end
