# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

module Submission::FlexibleRequestGraph
  # A doublet couples a source asset to a particular qc metric.
  # This allows us to pass the qc_metric downstream, without relying
  # on maintaining assets at each step. This is important as not only
  # to some requests generate their assets on the fly, but we'd need
  # to make sure that we had all appropriate well links and asset links
  # in place.
  Doublet = Struct.new(:asset, :qc_metric)

  class RequestChainError < RuntimeError; end

  class RequestChain
    attr_reader :order, :source_assets_qc_metrics, :preplexed, :built, :multiplexed
    alias_method :built?, :built
    alias_method :multiplexed?, :multiplexed
    alias_method :preplexed?, :preplexed

    delegate :product, to: :order

    def initialize(order, source_assets, multiplexing_assets)
      @order = order
      @source_assets_qc_metrics = source_assets.map { |asset| Doublet.new(asset, asset.latest_stock_metrics(product)) }
      @multiplexing_assets = multiplexing_assets
      @preplexed = multiplexing_assets.present?
      @built = false
      @multiplexed = false
    end

    def build!
      raise RequestChainError, 'Request chains can only be built once' if built?
      raise StandardError, 'No request types specified!' if request_types.empty?
      request_types.inject(source_assets_qc_metrics) do |source_assets_qc_metrics_memo, request_type|
        link = ChainLink.build!(request_type, multiplier_for(request_type), source_assets_qc_metrics_memo, self)
        break if preplexed && link.multiplexed?
        link.target_assets_qc_metrics
      end
      @built = true
    end

    ##
    # multiplexing_assets returns @multiplexing_assets if present
    # otherwise it yields to any presented block and assumes it returns
    # the multiplexing_assets
    def multiplexing_assets
      @multiplexed = true

      @multiplexing_assets ||= yield if block_given?
      @multiplexing_assets
    end

    private

    def request_types
      order.request_types.map { |request_type_id| RequestType.find(request_type_id) }
    end

    def multiplier_for(request_type)
      multipliers[request_type.id.to_s]
    end

    def multipliers
      @multipliers ||= Hash.new { |h, k| h[k] = 1 }.tap do |multipliers|
        requested_multipliers = order.request_options.try(:[], :multiplier) || {}
        requested_multipliers.each { |k, v| multipliers[k.to_s] = v.to_i }
      end
    end
  end

  ##
  # Builds all requests of a given request type and any target_assets
  # The build! method automatically creates a link of the appropriate class
  module ChainLink
    def self.included(base)
      base.class_eval do
        attr_reader :request_type, :multiplier, :source_assets_qc_metrics, :target_assets_qc_metrics, :chain
      end
    end

    def self.build!(request_type, multiplier, source_assets_qc_metrics, chain)
      link_class = request_type.for_multiplexing? ? MultiplexedLink : UnplexedLink
      link_class.new(request_type, multiplier, source_assets_qc_metrics, chain).tap do |link|
        link.build!
      end
    end

    def initialize(request_type, multiplier, source_assets_qc_metrics, chain)
      @request_type              = request_type
      @multiplier                = multiplier
      @source_assets_qc_metrics  = source_assets_qc_metrics
      @chain                     = chain
    end

    def multiplexed?; false; end

    def build!
      multiplier.times do |_|
        # Now we can iterate over the source assets and target assets building the requests between them.
        # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
        # are transferred into the destination if the request does not do this in some manner itself.
        source_asset_metrics_target_assets do |source_asset, qc_metrics, target_asset|
          chain.order.create_request_of_type!(
            request_type,
            asset: source_asset, target_asset: target_asset
          ).tap do |request|

            AssetLink.create_edge!(source_asset, target_asset) if source_asset.present? and target_asset.present?

            request.qc_metrics = qc_metrics.compact.uniq
            request.update_responsibilities!

            comments.each do |comment|
              request.comments.create!(user: user, description: comment)
            end if comments.present?
          end
        end
      end
      associate_built_requests!
    end

    def target_assets
      target_assets_qc_metrics.map(&:asset).flatten.uniq
    end

    private

    def comments
      (chain.order.comments || '').split("\n")
    end

    def user
      chain.order.user
    end

    def source_asset_metrics_target_assets
      new_target_assets = generate_target_assets
      source_assets_doublet_with_index do |doublet, index|
        yield(doublet.asset, doublet.qc_metric, new_target_assets[index].asset)
      end
    end

    def associate_built_requests!
      # Do Nothing
    end

    def create_target_asset(source_asset = nil)
      request_type.create_target_asset! do |asset|
        asset.generate_barcode
        asset.generate_name(source_asset.try(:name) || asset.barcode.to_s)
      end
    end
  end

  class MultiplexedLink
    include ChainLink

    def initialize(request_type, multiplier, assets, chain)
      raise RequestChainError unless request_type.for_multiplexing?
      raise RequestChainError, 'Cannot multiply multiplexed requests' if multiplier > 1
      super
    end

    def multiplexed?; true; end

    private

    def source_assets_doublet_with_index
      source_assets_qc_metrics.each do |doublet|
        yield(doublet, request_type.pool_index_for_asset(doublet.asset))
      end
    end

    # We can only do this once for multiplexed request types
    def generate_target_assets
      @target_assets_qc_metrics ||= chain.multiplexing_assets do
        # We yield only if we don't have any multiplexing assets
        all_qc_metrics = source_assets_qc_metrics.map { |doublet| doublet.qc_metric }.flatten.uniq
        Array.new(request_type.pool_count) { Doublet.new(create_target_asset, all_qc_metrics) }
      end
    end

    def associate_built_requests!
      downstream_requests.each do |request|
        request.update_attributes!(initial_study: nil) if request.initial_study != study
        request.update_attributes!(initial_project: nil) if request.initial_project != project
        comments.each do |comment|
          request.comments.create!(user: user, description: comment)
        end if comments.present?
      end
    end

    def downstream_requests
      target_assets.uniq.compact.map(&:requests).flatten
    end
  end

  class UnplexedLink
    include ChainLink

    def initialize(request_type, multiplier, assets, chain)
      raise RequestChainError if request_type.for_multiplexing?
      super
    end

    def generate_target_assets
      source_assets_qc_metrics.map do |doublet|
        Doublet.new(create_target_asset(doublet.asset), doublet.qc_metric)
      end.tap do |new_target_assets|
        @target_assets_qc_metrics ||= []
        @target_assets_qc_metrics.concat(new_target_assets)
      end
    end

    def source_assets_doublet_with_index
      source_assets_qc_metrics.each_with_index do |doublet, index|
        yield(doublet, index)
      end
    end
  end

  module OrderMethods
    def build_request_graph!(multiplexing_assets = nil)
      ActiveRecord::Base.transaction do
        RequestChain.new(self, assets, multiplexing_assets).tap do |chain|
          chain.build!
          yield chain.multiplexing_assets if chain.multiplexed?
        end
      end
    end
  end
end
