# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

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
    unless comment.blank?
      comment.destroy
    end
    @comments = @sample.comments
    render partial: 'list', locals: { commentable: @sample, visible: true }
  end

  private

  def discover_sample
    @sample = Sample.find(params[:sample_id])
  end
end
