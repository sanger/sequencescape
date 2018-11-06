class Assets::CommentsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_asset

  def index
    @comments = @asset.comments.order(created_at: :asc)
    if request.xhr?
      render partial: 'simple_list', locals: { descriptions: @comments.pluck(:description) }
    else
      # Perform default
    end
  end

  def create
    @asset.comments.create(description: params[:comment], user: current_user)
    @comments = @asset.comments
    render partial: 'list', locals: { commentable: @asset, visible: true }
  end

  def destroy
    comment = Comment.find(params[:id])
    unless comment.blank?
      comment.destroy
    end
    @comments = @asset.comments
    render partial: 'list', locals: { commentable: @asset, visible: true }
  end

  private

  def discover_asset
    @asset = Asset.find(params[:asset_id])
  end
end
