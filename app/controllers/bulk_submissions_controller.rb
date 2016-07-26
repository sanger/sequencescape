#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2013,2015 Genome Research Ltd.

require 'formtastic'

class BulkSubmissionsController < ApplicationController

  def index
    redirect_to :action => "new"
  end

  def new
    # default action - shows file upload form

    @submission_template_groups = SubmissionTemplate.visible.include_product_line.group_by {|t| t.product_line.try(:name)||'General' }
    @bulk_submission = BulkSubmission.new
  end

  def create
    begin
      @bulk_submission = BulkSubmission.new(:spreadsheet => params.fetch(:bulk_submission, {})[:spreadsheet])
      if @bulk_submission.valid?
        flash.now[:notice]  = "File was processed successfully"
        sub_ids,@sub_details = @bulk_submission.completed_submissions
        @these_subs     = Submission.find(sub_ids)
      else
        flash.now[:error] = "There was a problem with your upload"
        render :action => "new"
      end
    rescue ActiveRecord::RecordInvalid => exception
      flash.now[:error] = "There was a problem when building your submissions"
      @bulk_submission.errors.add(:base,exception.message)
      render :action => "new"
    end
  end

end
