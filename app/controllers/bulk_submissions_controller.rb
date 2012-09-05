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
  end

end
