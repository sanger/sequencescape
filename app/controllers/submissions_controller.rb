class SubmissionsController < ApplicationController

  def new
    @presenter = SubmissionCreater.new(current_user, :study_id => params[:study_id])
  end

  def create
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    if @presenter.save
      render :partial => 'saved_order',
        :locals => {
          :order => @presenter.order,
          :form => :dummy_form_symbol
        },
        :layout => false
    else
      render :partial => 'order_errors', :layout => false, :status => 422
    end

  end

  def edit
    @presenter = SubmissionCreater.new(current_user,  :id => params[:id] )
  end

  # This method will build a submission then redirect to the submission on completion
  def update
    @presenter = SubmissionCreater.new(current_user, :id => params[:id])

    @presenter.build_submission!

    redirect_to @presenter.submission
  end

  def index
    @building = Submission.building.find(:all, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
    @pending = Submission.pending.find(:all, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
    @ready = Submission.ready.find(:all, :limit => 10, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
  end

  def destroy
      submission = SubmissionPresenter.new(current_user, :id => params[:id])
      submission.destroy

      flash[:notice] = "Submission successfully deleted!"
      redirect_to :action => :index
  end

  def show
    @presenter = SubmissionPresenter.new(current_user, :id => params[:id])
  end

 def study
    @study       = Study.find(params[:id])
    @submissions = @study.submissions
  end

  ###################################################               AJAX ROUTES
  # TODO[sd9]: These AJAX routes could be re-factored
  def order_fields
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    render :partial => 'order_fields', :layout => false
  end

  def study_assets
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    render :partial => 'study_assets', :layout => false
  end
  ##################################################         End of AJAX ROUTES
end

