class Studies::CommentsController < ApplicationController
  before_filter :discover_study

  def index
    @comments = @study.comments.all(:order => "created_at ASC")
  end

  def create
    @study.comments.create(:description => params[:comment], :user_id => current_user.id)
    @comments = @study.comments
    render :partial => "list", :locals => { :commentable => @study, :visible => true }
  end

  def destroy
    comment = Comment.find(params[:id])
    unless comment.blank?
      comment.destroy
    end
    @comments = @study.comments
    render :partial => "list", :locals => { :commentable => @study, :visible => true }
  end

  private
  def discover_study
    @study = Study.find(params[:study_id])
  end
end
