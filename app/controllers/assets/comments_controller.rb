#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Assets::CommentsController < ApplicationController
  before_filter :discover_asset

  def index
    @comments = @asset.comments.all(:order => "comments.created_at ASC")
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
