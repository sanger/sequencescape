class Samples::CommentsController < ApplicationController
  before_filter :discover_sample

  def index
    @comments = @sample.comments.all(:order => "created_at ASC")
  end

  def create
    @sample.comments.create(:description => params[:comment], :user_id => current_user.id)
    @comments = @sample.comments
    render :partial => "list", :locals => { :commentable => @sample, :visible => true }
  end

  def destroy
    comment = Comment.find(params[:id])
    unless comment.blank?
      comment.destroy
    end
    @comments = @sample.comments
    render :partial => "list", :locals => { :commentable => @sample, :visible => true }
  end

  private
  def discover_sample
    @sample = Sample.find(params[:sample_id])
  end
end
