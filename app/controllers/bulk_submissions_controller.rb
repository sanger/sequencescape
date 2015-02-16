#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2013 Genome Research Ltd.
class BulkSubmissionsController < ApplicationController
  Formtastic::SemanticFormBuilder.inline_errors = :list

  def index
    redirect_to :action => "new"
  end

  def new
    # default action - shows file upload form
    @bulk_submission = BulkSubmission.new
  end

  def create
    begin
      @bulk_submission = BulkSubmission.new(:spreadsheet => params.fetch(:bulk_submission, {})[:spreadsheet])

      if @bulk_submission.valid?
        flash[:notice]  = "File was processed successfully"
        sub_ids,@sub_details = @bulk_submission.completed_submissions
        @these_subs     = Submission.find(sub_ids)
        #Submission.all(:conditions => ["created_at > :lastminute", { :lastminute => Time.now - 1.day}])

      else
        #flash[:error] = "There was a problem with your upload"
        # apparently this should redirect_to rather than render, but then the errors don't show up properly
        render :action => "new"
      end
    rescue ActiveRecord::RecordInvalid => exception
      flash[:error] = exception.message
      render :action => "new"
    end
  end

end
