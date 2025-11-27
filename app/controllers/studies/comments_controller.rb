# frozen_string_literal: true
class Studies::CommentsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_study

  def index
    @comments = @study.comments.order(:created_at)
  end

  def create
    @study.comments.create(description: params[:comment], user_id: current_user.id)
    @comments = @study.comments
    render partial: 'list', locals: { commentable: @study, visible: true }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @study.comments
    render partial: 'list', locals: { commentable: @study, visible: true }
  end

  private

  def discover_study
    @study = Study.find(params[:study_id])
  end
end
