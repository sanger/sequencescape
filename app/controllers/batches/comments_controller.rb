#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Batches::CommentsController < ApplicationController
  before_filter :discover_batch

  def index
    @comments = @batch.comments.all(:order => "created_at ASC")
  end

  def create
    @batch.comments.create(:description => params[:comment], :user_id => current_user.id)
    @comments = @batch.comments
    render :partial => "list", :locals => { :commentable => @batch, :visible => true }
  end

  def destroy
    comment = Comment.find(params[:id])
    unless comment.blank?
      comment.destroy
    end
    @comments = @batch.comments
    render :partial => "list", :locals => { :commentable => @batch, :visible => true }
  end

  private
  def discover_batch
    @batch = Batch.find(params[:batch_id])
  end
end
