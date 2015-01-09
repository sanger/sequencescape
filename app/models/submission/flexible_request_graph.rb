
module Submission::FlexibleRequestGraph

  def build_request_graph!(multiplexing_assets = nil, &block)
    ActiveRecord::Base.transaction do
      create_request_chain!(
        build_request_type_multiplier_pairs,
        assets.map { |asset| [ asset, :old_item ] },
        multiplexing_assets,
        &block
      )
    end
  end

  # Generates a list of RequestType and multiplier pairs for the instance.
  def build_request_type_multiplier_pairs
    # Ensure that the keys of the multipliers hash are strings, otherwise we get weirdness!
    multipliers = Hash.new { |h,k| h[k] = 1 }.tap do |multipliers|
      requested_multipliers = request_options.try(:[], :multiplier) || {}
      requested_multipliers.each { |k,v| multipliers[k.to_s] = v.to_i }
    end

    request_types.dup.map do |request_type_id|
      [ RequestType.find(request_type_id), multipliers[request_type_id.to_s] ]
    end
  end
  private :build_request_type_multiplier_pairs


  def create_target_asset_for!(request_type, source_asset = nil)
    request_type.create_target_asset! do |asset|
      asset.generate_barcode
      asset.generate_name(source_asset.try(:name) || asset.barcode.to_s)
    end
  end
  private :create_target_asset_for!

  # Creates the next step in the request graph, taking the first request type specified and building
  # enough requests for the source requests.  It will recursively call itself if there are more requests
  # that need creating.
  def create_request_chain!(request_type_and_multiplier_pairs, source_asset_item_pairs, multiplexing_assets, &block)
    raise StandardError, 'No request types specified!' if request_type_and_multiplier_pairs.empty?
    request_type, multiplier = request_type_and_multiplier_pairs.shift
    t = Time.now
    multiplier.times do |_|
      # If the request type is for multiplexing it means that all of the assets end up in one target asset.
      # Otherwise there are the same number of target assets as source.
      target_assets =
        if request_type.for_multiplexing?
          multiplexing_assets || request_type.pool_count.times.map { create_target_asset_for!(request_type) }
        else
          source_asset_item_pairs.map { |source_asset, _| create_target_asset_for!(request_type, source_asset) }
        end

      yield(target_assets) if block_given? and request_type.for_multiplexing?


      # Now we can iterate over the source assets and target assets building the requests between them.
      # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
      # are transferred into the destination if the request does not do this in some manner itself.
      source_asset_item_pairs.each_with_index do |(source_asset, item), index|
        eip = Time.now
        index = request_type.pool_index_for(source_asset) if request_type.for_multiplexing?
        target_asset = target_assets[index]

        create_request_of_type!(
          request_type,
          :asset => source_asset, :target_asset => target_asset
        ).tap do |request|
          # TODO: AssetLink is supposed to disappear at some point in the future because it makes no real sense
          # given that the request graph describes this relationship.
          AssetLink.create_edge!(source_asset, target_asset) if source_asset.present? and target_asset.present?

          comments.each do |comment|
            request.comments.create!(:user => user, :description => comment)
          end if comments.present?
        end
      end

      # Now we can continue to the next request type in the chain, using the target assets we've created.
      # We need to de-duplicate the multiplexed assets.  Note that we duplicate the pairs here so that
      # they don't get disrupted by the shift operation at the start of this method.
      next if request_type_and_multiplier_pairs.empty?

      target_assets_items =  if request_type.for_multiplexing?   # May have many nil assets for non-multiplexing
        if multiplexing_assets.nil?
          target_assets.map { |asset| [ asset, nil ] }
        else
          associate_built_requests(target_assets.compact); []
        end
      else
        target_assets.each_with_index.map do |asset,index|
          source_asset = request_type.no_target_asset? ? source_asset_item_pairs[index].first : asset
          [ source_asset, source_asset_item_pairs[index].last ]
        end
      end

      create_request_chain!(request_type_and_multiplier_pairs.dup, target_assets_items, multiplexing_assets, &block)
    end
  end
  private :create_request_chain!

  def associate_built_requests(assets)
    assets.map(&:requests).flatten.each do |request|
      request.update_attributes!(:initial_study => nil) if request.initial_study != study
      request.update_attributes!(:initial_project => nil) if request.initial_project != project
      comments.each do |comment|
        request.comments.create!(:user => user, :description => comment)
      end if comments.present?
    end
  end
  private :associate_built_requests


end
