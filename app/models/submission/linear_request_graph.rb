# This module can be included where the submission has a linear behaviour, with no branching.
module Submission::LinearRequestGraph
  # Source data is used to pass information down the request graph
  SourceData = Struct.new(:asset, :qc_metric, :sample)
  # TODO: When Item dies this code will not need to hand it around so much!

  # Builds the entire request graph for this submission.  If you want to reuse the multiplexing assets then
  # pass them in as the 'multiplexing_assets' parameter; specify a block if you want to know when they have
  # been used.
  def build_request_graph!(multiplexing_assets = nil, &block)
    ActiveRecord::Base.transaction do
      create_request_chain!(
        build_request_type_multiplier_pairs,
        assets.map { |asset| SourceData.new(asset, asset.latest_stock_metrics(product), nil) },
        multiplexing_assets,
        &block
      )
    end
  end

  private

  # Generates a list of RequestType and multiplier pairs for the instance.
  def build_request_type_multiplier_pairs
    # Ensure that the keys of the multipliers hash are strings, otherwise we get weirdness!
    multipliers = Hash.new { |h, k| h[k] = 1 }.tap do |multipliers|
      requested_multipliers = request_options.try(:[], :multiplier) || {}
      requested_multipliers.each { |k, v| multipliers[k.to_s] = v.to_i }
    end

    request_types.dup.map do |request_type_id|
      [RequestType.find(request_type_id), multipliers[request_type_id.to_s]]
    end
  end

  def create_target_asset_for!(request_type, source_asset = nil)
    request_type.create_target_asset! do |asset|
      asset.generate_barcode
      asset.generate_name(source_asset&.name || asset.try(:human_barcode))
    end
  end

  # Creates the next step in the request graph, taking the first request type specified and building
  # enough requests for the source requests.  It will recursively call itself if there are more requests
  # that need creating.
  def create_request_chain!(request_type_and_multiplier_pairs, source_data_set, multiplexing_assets, &block)
    raise StandardError, 'No request types specified!' if request_type_and_multiplier_pairs.empty?

    request_type, multiplier = request_type_and_multiplier_pairs.shift

    multiplier.times do
      # If the request type is for multiplexing it means that all of the assets end up in one target asset.
      # Otherwise there are the same number of target assets as source.
      target_assets =
        if request_type.for_multiplexing?
          multiplexing_assets || Array.new(source_data_set.length, create_target_asset_for!(request_type))
        else
          source_data_set.map { |source_data| create_target_asset_for!(request_type, source_data.asset) }
        end
      yield(target_assets) if block_given? and request_type.for_multiplexing?

      # Now we can iterate over the source assets and target assets building the requests between them.
      # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
      # are transferred into the destination if the request does not do this in some manner itself.
      source_data_set.each_with_index do |source_data, index|
        source_asset = source_data.asset
        qc_metrics = source_data.qc_metric
        target_asset = target_assets[index]

        create_request_of_type!(
          request_type,
          asset: source_asset, target_asset: target_asset
        ).tap do |request|
          # TODO: AssetLink is supposed to disappear at some point in the future because it makes no real sense
          # given that the request graph describes this relationship.
          # JG: Its removal only really makes sense if we can walk the request graph in a timely manner.
          AssetLink.create_edge!(source_asset, target_asset) if source_asset.present? and target_asset.present?

          request.qc_metrics = qc_metrics.compact.uniq
          request.update_responsibilities!

          comments.split("\n").each do |comment|
            request.comments.create!(user: user, description: comment)
          end if comments.present?
        end
      end

      # Now we can continue to the next request type in the chain, using the target assets we've created.
      # We need to de-duplicate the multiplexed assets.  Note that we duplicate the pairs here so that
      # they don't get disrupted by the shift operation at the start of this method.
      next if request_type_and_multiplier_pairs.empty?

      target_assets_items =
        if request_type.for_multiplexing? # May have many nil assets for non-multiplexing
          if multiplexing_assets.nil?
            criteria = source_data_set.map(&:qc_metric).flatten.uniq
            target_assets.uniq.map { |asset| SourceData.new(asset, criteria, nil) }
          else
            associate_built_requests(target_assets.uniq.compact)
            SourceData.new(nil, nil, nil)
          end
        else
          target_assets.each_with_index.map do |asset, index|
            source_asset = request_type.no_target_asset? ? source_data_set[index].first : asset
            SourceData.new(source_asset, source_data_set[index].qc_metric, nil)
          end
        end

      create_request_chain!(request_type_and_multiplier_pairs.dup, target_assets_items, multiplexing_assets, &block)
    end
  end

  def associate_built_requests(assets)
    assets.map(&:requests).flatten.each do |request|
      request.update!(initial_study: nil) if request.initial_study != study
      request.update!(initial_project: nil) if request.initial_project != project
      comments.split("\n").each do |comment|
        request.comments.create!(user: user, description: comment)
      end if comments.present?
    end
  end
end
