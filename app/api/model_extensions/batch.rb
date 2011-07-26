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
          :uuid_object, :study, :project, :request_metadata, :request_type,
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

  # Cancels downstream requests of this batch based on the determination of the block.  A request
  # is passed to the block and it then returns a determination.  If that is :none then all subsequent
  # requests of this request are cancelled; if it's nil then none of them are; and if it's a number
  # then that number are kept, any others are cancelled.
  def keep_downstream_requests(&block)
    requests.each do |request|
      amount_to_keep     = yield(request)
      requests_to_cancel = request.next_requests(pipeline)

      requests_to_cancel = 
        case amount_to_keep
        when nil   then []
        when :none then requests_to_cancel
        else requests_to_cancel.slice(amount_to_keep, requests_to_cancel.length) || []
        end

      requests_to_cancel.map(&:cancel!)
    end
  end

  def generate_target_assets_for_requests
    requests_to_update, asset_links = [], []

    asset_type = pipeline.asset_type.constantize
    requests(:reload).each do |request|
      # we need to call downstream request before setting the target_asset
      # otherwise, the request use the target asset to find the next request
      target_asset = asset_type.create! do |asset|
        asset.barcode  = AssetBarcode.new_barcode unless [ Lane, Well ].include?(asset_type)
        asset.generate_name(request.asset.name)
      end.tap do |asset|
        asset.aliquots = request.asset.aliquots.map(&:clone)
      end

      downstream_requests_needing_asset(request) do |downstream_requests|
        requests_to_update.concat(downstream_requests.map { |r| [ r.id, target_asset.id ] })
      end

      request.update_attributes!(
        :state        => 'started',
        :target_asset => target_asset 
      )

      # All links between the two assets as new, so we can bulk create them!
      asset_links << AssetLink.build_edge(request.asset, request.target_asset)

    end

    AssetLink.import(asset_links, :validate => false) unless asset_links.empty?

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
    not pipeline.asset_type.blank? and pipeline.request_type.try(:target_asset_type).blank?
  end
  private :need_target_assets_on_requests?
end
