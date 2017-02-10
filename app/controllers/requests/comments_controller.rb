# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Requests::CommentsController < ApplicationController
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
    unless comment.blank?
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
