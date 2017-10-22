# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

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
    unless comment.blank?
      comment.destroy
    end
    @comments = @study.comments
    render partial: 'list', locals: { commentable: @study, visible: true }
  end

  private

  def discover_study
    @study = Study.find(params[:study_id])
  end
end
