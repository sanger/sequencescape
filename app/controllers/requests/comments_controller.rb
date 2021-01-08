class Requests::CommentsController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_request

  def index
    @comments = @request.comments.order('created_at ASC')
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
    if comment.present?
      comment.destroy
    end
    @comments = @request.comments
    render partial: 'list', locals: { commentable: @request, visible: true }
  end

  private

  def discover_request
    @request = Request.find(params[:request_id])
  end
end
