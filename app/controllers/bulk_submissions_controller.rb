# encoding: utf-8
# frozen_string_literal: true

require 'formtastic'

class BulkSubmissionsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :find_submission_template_groups, only: %i[new create]

  DEFAULT_SUBMISSION_TEMPLATE_GROUP = 'General'

  def index
    redirect_to action: 'new'
  end

  def new
    # default action - shows file upload form
    @bulk_submission = BulkSubmission.new
  end

  # rubocop:todo Metrics/MethodLength
  def create # rubocop:todo Metrics/AbcSize
    @bulk_submission = BulkSubmission.new(params.fetch(:bulk_submission, {}))
    if @bulk_submission.valid?
      flash.now[:notice] = 'File was processed successfully'
      sub_ids, @sub_details = @bulk_submission.completed_submissions
      @these_subs = Submission.find(sub_ids)
    else
      flash.now[:error] = 'There was a problem with your upload'
      render action: 'new'
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    flash.now[:error] = 'There was a problem when building your submissions'
    render action: 'new'
  end

  # rubocop:enable Metrics/MethodLength

  private

  def find_submission_template_groups
    @submission_template_groups =
      SubmissionTemplate.visible.include_product_line.group_by do |t|
        t.product_line.try(:name) || DEFAULT_SUBMISSION_TEMPLATE_GROUP
      end
  end
end
