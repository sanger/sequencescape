module ModelExtensions::Batch
  def self.included(base)
    base.class_eval do
      # These were in Batch but it makes more sense to keep them here for the moment
      has_many :batch_requests, :include => :request
      has_many :requests, :through => :batch_requests do
        # we redefine count to use the fast one.
        # the normal request.count is slow because of the eager load of requests in batch_request
        def count
          proxy_owner.request_count
        end
      end

      # This is the new stuff ...
      accepts_nested_attributes_for :requests

      named_scope :include_pipeline, :include => { :pipeline => :uuid_object }
      named_scope :include_user, :include => :user
      named_scope :include_requests, :include => {
        :requests => [
          :uuid_object, :request_metadata, :request_type,
          { :submission   => :uuid_object },
          { :asset        => [ :uuid_object, :barcode_prefix, { :aliquots => [ :sample, :tag ] } ] },
          { :target_asset => [ :uuid_object, :barcode_prefix, { :aliquots => [ :sample, :tag ] } ] }
        ]
      }

      after_create :generate_target_assets_for_requests, :if => :need_target_assets_on_requests?
      before_save :manage_downstream_requests
    end
  end

  def manage_downstream_requests
    pipeline.manage_downstream_requests(self)
  end
  private :manage_downstream_requests

  def generate_target_assets_for_requests
    requests_to_update, asset_links = [], []

    asset_type = pipeline.asset_type.constantize
    requests(:reload).each do |request|
      # we need to call downstream request before setting the target_asset
      # otherwise, the request use the target asset to find the next request
      target_asset = asset_type.create! do |asset|
        asset.barcode  = AssetBarcode.new_barcode unless [ Lane, Well ].include?(asset_type)
        asset.generate_name(request.asset.name)
      end

      downstream_requests_needing_asset(request) do |downstream_requests|
        requests_to_update.concat(downstream_requests.map { |r| [ r.id, target_asset.id ] })
      end

      request.update_attributes!(:target_asset => target_asset)

      # Do not start requests here as the batch will not be started and it will try
      # to start the requests when someone does something with the batch.
      #request.start!

      # All links between the two assets as new, so we can bulk create them!
      asset_links << [request.asset.id, request.target_asset.id]
    end

    AssetLink::BuilderJob.create(asset_links)

    Request.import(
      [ :id, :asset_id ],
      requests_to_update,
      :on_duplicate_key_update => [ :asset_id ],
      :validate => false
    ) unless requests_to_update.empty?
  end
  private :generate_target_assets_for_requests

  def downstream_requests_needing_asset(request)
    next_requests_needing_asset = request.next_requests(pipeline).select { |r| r.asset_id.blank? }
    yield(next_requests_needing_asset) unless next_requests_needing_asset.blank?
  end

  def need_target_assets_on_requests?
    pipeline.asset_type.present? and pipeline.request_types.detect(&:needs_target_asset?).present?
  end
  private :need_target_assets_on_requests?
end
