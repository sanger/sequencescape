# frozen_string_literal: true
class Samples::CommentsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_sample

  def index
    @comments = @sample.comments.order(:created_at)
  end

  def create
    @sample.comments.create(description: params[:comment], user_id: current_user.id)
    @comments = @sample.comments
    render partial: 'list', locals: { commentable: @sample, visible: true }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @sample.comments
    render partial: 'list', locals: { commentable: @sample, visible: true }
  end

  private

  def discover_sample
    @sample = Sample.find(params[:sample_id])
  end
end
