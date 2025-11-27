# frozen_string_literal: true
class Requests::CommentsController < ApplicationController
  before_action :discover_request

  def index
    commentables = [@request, @request.asset, @request.asset&.labware].compact
    @comments = Comment.where(commentable: commentables).order(:created_at)
    if request.xhr?
      render partial: 'simple_list', locals: { descriptions: @comments.pluck(:description) }
    else
      # Perform default
    end
  end

  def create
    @request.comments.create(description: params[:comment], user_id: current_user.id)
    @comments = @request.comments
    render partial: 'list', locals: { commentable: @request, visible: true }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @request.comments
    render partial: 'list', locals: { commentable: @request, visible: true }
  end

  private

  def discover_request
    @request = Request.find(params[:request_id])
  end
end
