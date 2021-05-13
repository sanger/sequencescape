# The stock assets controller makes stock assets for
# the products of batches. Originally this behaviour
# was on BathcesController#new_stock_assets.
class StockAssetsController < ApplicationController
  before_action :find_batch, only: :new

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def new # rubocop:todo Metrics/CyclomaticComplexity
    if @batch.requests.empty?
      redirect_to @batch, alert: 'No requests to create stock tubes'
    else
      batch_assets =
        if @batch.multiplexed?
          candidate_multiplexed_library = @batch.target_assets.first.children.first

          if candidate_multiplexed_library.nil?
            redirect_to batch_path(@batch), alert: "There's no multiplexed library tube available to have a stock tube."
            []
          elsif candidate_multiplexed_library.has_stock_asset? || candidate_multiplexed_library.is_a_stock_asset?
            redirect_to batch_path(@batch), alert: 'Stock tubes have already been created'
            []
          else
            [candidate_multiplexed_library]
          end
        else
          @batch
            .target_assets
            .reject(&:has_stock_asset?)
            .tap do |batch_assets|
              redirect_to batch_path(@batch), alert: 'Stock tubes have already been created' if batch_assets.empty?
            end
        end

      @assets =
        batch_assets.each_with_object({}) { |asset, assets| assets[asset.labware.id] = asset.labware.new_stock_asset }
    end
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def create # rubocop:todo Metrics/AbcSize
    params[:assets].each do |id, params|
      asset = Labware.find(id)
      stock_asset =
        asset.create_stock_asset!(name: params[:name], volume: params[:volume], concentration: params[:concentration])
      stock_asset.assign_relationships(asset.parents, asset)
    end
    flash[:notice] =
      "#{params[:assets].to_unsafe_h.count} stock #{'tubes'.pluralize(params[:assets].to_unsafe_h.count)} created"
    redirect_to batch_path(params[:batch_id])
  end

  private

  def find_batch
    @batch = Batch.find(params[:batch_id])
  end
end
