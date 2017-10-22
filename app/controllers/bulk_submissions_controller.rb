# Encoding: utf-8
# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2013,2015 Genome Research Ltd.

require 'formtastic'

class BulkSubmissionsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :find_submission_template_groups, only: [:new, :create]

  DEFAULT_SUBMISSION_TEMPLATE_GROUP = 'General'

  def index
    redirect_to action: 'new'
  end

  def new
    # default action - shows file upload form
    @bulk_submission = BulkSubmission.new
  end

  def create
    begin
      @bulk_submission = BulkSubmission.new(params.fetch(:bulk_submission, {}))
      if @bulk_submission.valid?
        flash.now[:notice] = 'File was processed successfully'
        sub_ids, @sub_details = @bulk_submission.completed_submissions
        @these_subs = Submission.find(sub_ids)
      else
        flash.now[:error] = 'There was a problem with your upload'
        render action: 'new'
      end
    rescue ActiveRecord::RecordInvalid => exception
      flash.now[:error] = 'There was a problem when building your submissions'
      @bulk_submission.errors.add(:base, exception.message)
      render action: 'new'
    end
  end

  private

  def find_submission_template_groups
    @submission_template_groups = SubmissionTemplate.visible.include_product_line.group_by { |t| t.product_line.try(:name) || DEFAULT_SUBMISSION_TEMPLATE_GROUP }
  end
end
