# frozen_string_literal: true

# Associations related to {Receptacle} also included in {Asset} when not refactoring
module ReceptacleAssociations
  extend ActiveSupport::Concern
  included do
    belongs_to :map

    has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset, foreign_key: :asset_id
    has_many :asset_groups, through: :asset_group_assets
    has_many :qc_results, dependent: :destroy, foreign_key: :asset_id, inverse_of: :asset
    has_many :sample_manifest_assets, dependent: :destroy
    has_many :sample_manifests, through: :sample_manifest_assets
  end
end
