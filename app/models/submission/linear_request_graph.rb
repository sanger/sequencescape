# frozen_string_literal: true
# This module can be included where the {Order} has a linear behaviour,
# with no branching. Eg. in {LinearSubmission}
module Submission::LinearRequestGraph
  # Source data is used to pass information down the request graph
  # asset
  # @attr asset             [Receptacle, nil]   The asset from which the request will be build.
  #                                              nil indicates no upstream asset in cases where target assets
  #                                              are generated later.
  # @attr qc_metric         [QcMetric]     The Qc Metric associated with this asset for this request type
  # @attr previous_requests [Array<Request>, nil] Used to pass requests down the chain when building the
  #                                        request graph. Used to. eg. pass down libraries
  SourceData = Struct.new(:asset, :qc_metric, :sample)

  # Builds the entire request graph for this {Order}
  # This is called from {Submission#process_submission!} which processes each order in turn,
  # multiplexing_assets returned by the first order get passed into subsequent orders.
  # @note The block behaviour here looks a bit odd, and is a result of the previous behaviour
  #       in which the multiplexing assets were yielded directly to the submission.
  #       This behaviour can be simplified eventually, but is maintained for the time being to
  #       reduce risk of a more significant re-write.
  def build_request_graph!(multiplexing_assets = nil)
    ActiveRecord::Base.transaction do
      mx_assets_tmp = nil
      create_request_chain!(
        build_request_type_multiplier_pairs,
        assets.map { |asset| SourceData.new(asset, asset.latest_stock_metrics(product), nil) },
        multiplexing_assets
      ) { |a| mx_assets_tmp = a }
      mx_assets_tmp
    end
  end

  private

  # Returns an array of arrays.
  # The inner array has two elements: a RequestType instance, and an integer (the "multiplier").
  # e.g. [ [ RequestType instance 1, 1 ], [ RequestType instance 2, 1 ] ]
  def build_request_type_multiplier_pairs # rubocop:todo Metrics/AbcSize
    # Ensure that the keys of the multipliers hash are strings, otherwise we get weirdness!
    multipliers =
      Hash
        .new { |h, k| h[k] = 1 }
        .tap do |multipliers|
          requested_multipliers = request_options.try(:[], :multiplier) || {}
          requested_multipliers.each { |k, v| multipliers[k.to_s] = v.to_i }
        end

    request_types.dup.map { |request_type_id| [RequestType.find(request_type_id), multipliers[request_type_id.to_s]] }
  end

  def create_target_asset_for!(request_type, source_asset = nil)
    request_type.create_target_asset! do |asset|
      asset.generate_barcode
      asset.generate_name(source_asset&.name || asset.try(:human_barcode))
    end
  end

  # Creates the next step in the request graph, taking the first request type specified and building
  # enough requests for the source assets.  It will recursively call itself if there are more requests
  # that need creating.
  # @yieldreturn [Array<Asset>] For orders with multiplexed request types, yields the target asset of
  #                             the multiplexing, such as a {MultiplexedLibraryTube}.
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def create_request_chain!(request_type_and_multiplier_pairs, source_data_set, multiplexing_assets, &block) # rubocop:todo Metrics/CyclomaticComplexity
    raise StandardError, 'No request types specified!' if request_type_and_multiplier_pairs.empty?

    request_type, multiplier = request_type_and_multiplier_pairs.shift

    # rubocop:todo Metrics/BlockLength
    multiplier.times do
      # If the request type is for multiplexing it means that all of the assets end up in one target asset.
      # Otherwise there are the same number of target assets as source.
      target_assets =
        if request_type.for_multiplexing?
          multiplexing_assets || Array.new(source_data_set.length, create_target_asset_for!(request_type))
        else
          source_data_set.map { |source_data| create_target_asset_for!(request_type, source_data.asset) }
        end
      yield(target_assets) if block && request_type.for_multiplexing?

      # Now we can iterate over the source assets and target assets building the requests between them.
      # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
      # are transferred into the destination if the request does not do this in some manner itself.
      source_data_set.each_with_index do |source_data, index|
        source_asset = source_data.asset
        qc_metrics = source_data.qc_metric
        target_asset = target_assets[index]

        create_request_of_type!(request_type, asset: source_asset, target_asset: target_asset).tap do |request|
          request.qc_metrics = qc_metrics.compact.uniq
          request.update_responsibilities!

          if comments.present?
            comments.split("\n").each { |comment| request.comments.create!(user: user, description: comment) }
          end
        end
      end

      # Now we can continue to the next request type in the chain, using the target assets we've created.
      # We need to de-duplicate the multiplexed assets.  Note that we duplicate the pairs here so that
      # they don't get disrupted by the shift operation at the start of this method.
      next if request_type_and_multiplier_pairs.empty?

      target_data_set =
        if request_type.for_multiplexing?
          # May have many nil assets for non-multiplexing
          if multiplexing_assets.nil?
            criteria = source_data_set.map(&:qc_metric).flatten.uniq
            target_assets.uniq.map { |asset| SourceData.new(asset, criteria, nil) }
          else
            associate_built_requests(target_assets.uniq.compact)
            []
          end
        else
          target_assets.each_with_index.map do |asset, index|
            source_asset = request_type.no_target_asset? ? source_data_set[index].first : asset
            SourceData.new(source_asset, source_data_set[index].qc_metric, nil)
          end
        end

      create_request_chain!(request_type_and_multiplier_pairs.dup, target_data_set, multiplexing_assets, &block)
    end
    # rubocop:enable Metrics/BlockLength
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def associate_built_requests(assets) # rubocop:todo Metrics/AbcSize
    assets
      .map(&:requests)
      .flatten
      .each do |request|
        request.update!(initial_study: nil) if request.initial_study != study
        request.update!(initial_project: nil) if request.initial_project != project
        if comments.present?
          comments.split("\n").each { |comment| request.comments.create!(user: user, description: comment) }
        end
      end
  end
end
