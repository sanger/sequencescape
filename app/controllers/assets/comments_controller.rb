class Assets::CommentsController < ApplicationController
  before_filter :discover_asset

  def index
    @comments = @asset.comments.all(:order => "created_at ASC")
  end

  def create
    @asset.comments.create(:description => params[:comment], :user_id => current_user.id)
    @comments = @asset.comments
    render :partial => "list", :locals => { :commentable => @asset, :visible => true }
  end

  def destroy
    comment = Comment.find(params[:id])
    unless comment.blank?
      comment.destroy
    end
    @comments = @asset.comments
    render :partial => "list", :locals => { :commentable => @asset, :visible => true }
  end

  private
  def discover_asset
    @asset = Asset.find(params[:asset_id])
  end
end
