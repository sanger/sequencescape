class RequestFactory

  def self.copy_request(request)
    ActiveRecord::Base.transaction do
      raise QuotaException.new, "Insufficient quota for #{request.request_type.name}" unless request.project.has_quota?(request.request_type, 1)

      request.class.create!(request.attributes) do |request_copy|
        request_copy.target_asset_id = nil
        request_copy.state           = "pending"
        request_copy.create_request_metadata(request.request_metadata.attributes)
        request_copy.created_at      = Time.now
      end
    end
  end

  def self.create_requests(study, project, workflow, user, asset_ids, request_type_ids, properties_hash, multiplier = 1)
    ActiveRecord::Base.transaction do
      submission = Submission.create!(
      :study => study,
      :project => project,
      :workflow => workflow,
      :user => user,
      :assets => asset_ids,
      :request_types => request_type_ids,
      :request_options => properties_hash,
      :state => :ready)

      requestFactory = RequestFactory.new(submission)
      requests = requestFactory.create_requests(multiplier)
      submission.save!
      [submission, requests]    
     end
  end
  
  def request_multiplier_to_sym(request_type_multipliers)
    request_types_to_sym = {}
    request_type_multipliers.each do |key,value|
      request_types_to_sym[:"#{key}"] = value
    end
    request_types_to_sym
  end

  def create_requests(multiplier = 1)
    requests = []
    ActiveRecord::Base.transaction do
      request_type_multiplier = {} # Individual multiplier for each request type
      request_type_multiplier = request_multiplier_to_sym(@submission.request_options[:multiplier]) if @submission.request_options.present? and @submission.request_options[:multiplier].present?

      1.upto(multiplier) do
        @assets.each do |asset|
          item = create_item(asset)

          if @submission.multiplexed?
            requests << create_request_chain_from_request_types(@mpx_request_types, item, asset, request_type_multiplier)
          else
            requests = create_request_chain_from_request_types(@non_mpx_request_types,item, asset, request_type_multiplier)
          end
        end

        if @submission.multiplexed?
          @non_mpx_request_types.each do |request_type|
            if request_type_multiplier && (! request_type_multiplier[:"#{request_type.id}"].nil?)
              request_type_multiplier[:"#{request_type.id}"].to_i.times do
                requests << create_request(request_type)
              end
            else  
              requests << create_request(request_type)
            end
          end
        end
      end
    end
    requests
  end
  
  def create_request_chain_from_request_types(request_types,item, asset, request_type_multiplier)
    create_request_chain(convert_multiplier_to_int(sorted_request_types_and_counts(request_types), request_type_multiplier), item, asset)
  end
  
  def sorted_request_types_and_counts(request_types)
    request_types.sort{ |a, b| a.order_with_default <=> b.order_with_default }.map{ |rt| [rt, 1] }    
  end
  
  def convert_multiplier_to_int(request_types_and_counts, request_type_multiplier)
    request_types_and_counts.each do |request_type_and_count|
      unless request_type_multiplier[:"#{request_type_and_count.first.id}"].nil?
        unless request_type_multiplier[:"#{request_type_and_count.first.id}"].nil? || request_type_multiplier[:"#{request_type_and_count.first.id}"] == 1
          request_type_and_count[1] = request_type_multiplier[:"#{request_type_and_count.first.id}"].to_i
        end
      end
    end
    
    request_types_and_counts
  end


  def create_request_chain(request_types_and_counts, item, asset)
    requests = []
    return requests if request_types_and_counts.size < 1

    request_type, multiplier = request_types_and_counts.shift

    multiplier.times do
      # we create the target first (if needed) to pass it to the request creator
      # so we don't need to save request again and again
      target_asset = create_target_asset(asset, request_type) # this may or not create a target depending of the request_type

      request = create_request(request_type, item, asset, target_asset)
      AssetLink.connect(asset, target_asset) if target_asset.present?

      requests << request

      next_asset = target_asset || asset
      requests += create_request_chain(request_types_and_counts, item, next_asset)
    end

    return requests
  end

  def create_request(request_type, item = nil, asset = nil, target_asset = nil)
    # we don't need to save the request now, as we are doing it at the end
    request = @submission.create_request_of_type!(
      request_type,
      :asset        => asset,
      :item         => item,
      :target_asset => target_asset
    )

    #we need to save the request before creating stuff belonging to a it
    set_comments(request)

    return request
  end

  def create_target_asset(source_asset, request_type)
    self.class.create_target_asset(source_asset, request_type)
  end
  def self.create_target_asset(source_asset, request_type)
    return if request_type.target_asset_type.blank?
    request_type.target_asset_type.constantize.create! do |asset|
      asset.barcode = AssetBarcode.new_barcode unless ["Lane", "Well"].include?(request_type.target_asset_type)
      asset.generate_name(source_asset.name)
    end.tap do |asset|
      asset.aliquots = source_asset.aliquots.map(&:clone)
    end
  end

  private

  def initialize(submission)
    @submission = submission
    @assets = Asset.find(@submission.assets)

    @non_mpx_request_types = []
    @mpx_request_types = []
    
    @submission.request_types.each do |request_type_id|
      request_type = RequestType.find(request_type_id)
      if request_type
        if request_type.for_multiplexing?
          @mpx_request_types << request_type
        else
          @non_mpx_request_types << request_type
        end
      end
    end
  end

  def set_comments(request)
    if @submission.comments
      @submission.comments.each do |comment|
        request.comments.create!(:user => @submission.user, :description => comment)
      end
    end
  end

  def create_item(asset)
    item = nil
    if asset.requests.size > 0
      item = asset.requests.first.item
    end

    unless item
      asset_name = asset.name ? asset.name : "#{asset.sti_type} #{asset.id}"
      item = Item.create!(:workflow => @submission.workflow, :name => asset_name + " " + @submission.id.to_s, :submission => @submission)
      asset.save!
    end

    item
  end
  
  # NOTE: This must remain as taking Asset ID and Study ID values, and not be converted to Assets and Study objects, because
  # delayed job does not work with actual ActiveRecord objects.
  def self.create_assets_requests(asset_ids, study_id)
    raise StandardError, "Can only accept asset IDs" unless asset_ids.all? { |i| i.is_a?(Fixnum) or i.is_a?(String) }
    raise StandardError, "Can only accept study ID" unless study_id.is_a?(Fixnum) or study_id.is_a?(String)

    # internal requests to link study -> request -> asset -> sample
    # TODO: do this as a submission
    request_type = RequestType.find_by_key('create_asset') or raise StandardError, "Cannot find create asset request type"
    requests = asset_ids.map { |asset_id| request_type.new(:study_id => study_id, :asset_id => asset_id) }
    Request.import requests
  end
end
