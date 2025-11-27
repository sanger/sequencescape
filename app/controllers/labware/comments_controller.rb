# frozen_string_literal: true

# Add comments to labware
class Labware::CommentsController < ApplicationController
  before_action :discover_labware

  def index
    @comments = @labware.comments.order(created_at: :asc)
    if request.xhr?
      render partial: 'simple_list', locals: { descriptions: @comments.pluck(:description) }
    else
      render :index
    end
  end

  def create
    @labware.comments.create(description: params[:comment], user: current_user)
    @comments = @labware.comments
    render partial: 'list', locals: { commentable: @labware, visible: true, labware: @labware }
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.presence&.destroy
    @comments = @labware.comments
    render partial: 'list', locals: { commentable: @labware, visible: true, labware: @labware }
  end

  private

  def discover_labware
    @labware = Labware.find(params[:labware_id])
  end
end
