#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

class SubmissionsController < ApplicationController

  before_filter :lab_manager_login_required, :only => [:change_priority]

  after_filter :set_cache_disabled!, :only => [:new, :index]

  def new
    self.expires_now
    @presenter = Submission::SubmissionCreator.new(current_user, :study_id => params[:study_id])
  end

  def create
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission])

    if @presenter.save
      render :partial => 'saved_order',
        :locals => {
          :presenter => @presenter,
          :order     => @presenter.order,
          :form      => :dummy_form_symbol
        },
        :layout => false
    else
      render :partial => 'order_errors', :layout => false, :status => 422
    end

  end

  def edit
    @presenter = Submission::SubmissionCreator.new(current_user,  :id => params[:id] )
  end

  # This method will build a submission then redirect to the submission on completion
  def update
    @presenter = Submission::SubmissionCreator.new(current_user, :id => params[:id])

    @presenter.build_submission!

    flash[:error] = "The submission could not be built: #{@presenter.submission.errors.full_messages}" if @presenter.submission.errors.present?

    render :show
  end

  def change_priority
    Submission.find(params[:id]).update_attributes!(:priority=>params[:submission][:priority])
    redirect_to :action=>:show, :id=>params[:id]
  end

  def index
    # Disable cache of this page
    self.expires_now

    @building = Submission.building.find(:all, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
    @pending = Submission.pending.find(:all, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
    @ready = Submission.ready.find(:all, :limit => 10, :order => "created_at DESC", :conditions => { :user_id => current_user.id })
  end

  def destroy
    ActiveRecord::Base.transaction do
      submission = Submission::SubmissionPresenter.new(current_user, :id => params[:id])
      if submission.destroy
        flash[:notice] = "Submission successfully deleted!"
      else
        flash[:error] = "This submission can't be deleted"
      end
      redirect_to :action => :index
    end
  end

  def show
    @presenter = Submission::SubmissionPresenter.new(current_user, :id => params[:id])
  end

 def study
    @study       = Study.find(params[:id])
    @submissions = @study.submissions
  end

  ###################################################               AJAX ROUTES
  # TODO[sd9]: These AJAX routes could be re-factored
  def order_fields
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission])

    render :partial => 'order_fields', :layout => false
  end

  def study_assets
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission])

    render :partial => 'study_assets', :layout => false
  end
  ##################################################         End of AJAX ROUTES
end

