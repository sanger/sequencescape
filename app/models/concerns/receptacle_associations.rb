# frozen_string_literal: true

# Associations related to {Receptacle} also included in {Asset} when not refactoring
module ReceptacleAssociations
  extend ActiveSupport::Concern
  included do
    has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset, foreign_key: :asset_id
    has_many :asset_groups, through: :asset_group_assets
    has_many :qc_results, dependent: :destroy, foreign_key: :asset_id, inverse_of: :asset
    # TODO: Remove 'requests' and 'source_request' as they are abiguous
    # :requests should go before :events_on_requests, through: :requests
    belongs_to :map
    has_many :requests, dependent: :restrict_with_exception
    has_many :events_on_requests, through: :requests, source: :events, validate: false
    has_one  :source_request,     -> { includes(:request_metadata) },
             class_name: 'Request', foreign_key: :target_asset_id, dependent: :restrict_with_exception,
             inverse_of: :target_aset
    has_many :requests_as_source, -> { includes(:request_metadata) },
             class_name: 'Request', foreign_key: :asset_id, dependent: :restrict_with_exception,
             inverse_of: :asset
    has_many :requests_as_target, -> { includes(:request_metadata) },
             class_name: 'Request', foreign_key: :target_asset_id, dependent: :restrict_with_exception,
             inverse_of: :target_asset
    has_many :sample_manifest_assets, dependent: :destroy
    has_many :sample_manifests, through: :sample_manifest_assets
  end
end
