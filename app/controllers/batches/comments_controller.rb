# frozen_string_literal: true
class Batches::CommentsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_batch

  def index
    @comments = @batch.comments.order(created_at: :asc)
  end

  def create
    @batch.comments.create(description: params[:comment], user_id: current_user.id)
    @comments = @batch.comments
    render partial: 'list', locals: { commentable: @batch, visible: true }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @batch.comments
    render partial: 'list', locals: { commentable: @batch, visible: true }
  end

  private

  def discover_batch
    @batch = Batch.find(params[:batch_id])
  end
end
