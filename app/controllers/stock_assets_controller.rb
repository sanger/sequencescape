# The stock assets controller makes stock assets for
# the products of batches. Originally this behaviour
# was on BathcesController#new_stock_assets.
class StockAssetsController < ApplicationController

  before_action :find_batch, only: :new

  def new
    if @batch.requests.empty?
      redirect_to @batch, alert: 'No requests to create stock tubes'
    else
      batch_assets = []

      if @batch.multiplexed?
        unless @batch.requests.first.target_asset.children.empty?
          multiplexed_library = @batch.requests.first.target_asset.children.first

          if !multiplexed_library.has_stock_asset? && !multiplexed_library.is_a_stock_asset?
            batch_assets = [multiplexed_library]
          else
            redirect_to batch_path(@batch), alert: 'Stock tubes have already been created'
          end
        else
          redirect_to batch_path(@batch), alert: "There's no multiplexed library tube available to have a stock tube."
        end
      else
        batch_assets = @batch.target_assets.reject { |a| a.has_stock_asset? }
        # batch_assets.reject! { |a| a.has_stock_asset? }
        if batch_assets.empty?
          redirect_to batch_path(@batch), alert: 'Stock tubes have already been created'
        end
      end

      @assets = {}
      batch_assets.each do |batch_asset|
        @assets[batch_asset.id] = batch_asset.new_stock_asset
      end
    end
  end

  def create
    params[:assets].each do |id, params|
      asset = Asset.find(id)
      stock_asset = asset.create_stock_asset!(
        name: params[:name],
        volume: params[:volume],
        concentration: params[:concentration]
      )
      stock_asset.assign_relationships(asset.parents, asset)
    end
    flash[:notice] = "#{params[:assets].count} stock #{'tubes'.pluralize(params[:assets].count)} created"
    redirect_to batch_path(params[:batch_id])
  end

  private

  def find_batch
    @batch = Batch.find(params[:batch_id])
  end
end
