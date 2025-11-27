# frozen_string_literal: true

# Ad and view {Comment comments} on {Receptacle receptacles}
class Receptacles::CommentsController < ApplicationController
  before_action :discover_receptacle

  def index
    @comments = @receptacle.comments.order(created_at: :asc)
    if request.xhr?
      render partial: 'simple_list', locals: { descriptions: @comments.pluck(:description) }
    else
      # Perform default
      render :index
    end
  end

  def create
    @receptacle.comments.create(description: params[:comment], user: current_user)
    @comments = @receptacle.comments
    render partial: 'list', locals: { commentable: @receptacle, visible: true, receptacle: @receptacle }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @receptacle.comments
    render partial: 'list', locals: { commentable: @receptacle, visible: true, receptacle: @receptacle }
  end

  private

  def discover_receptacle
    @receptacle = Receptacle.find(params[:receptacle_id])
  end
end
