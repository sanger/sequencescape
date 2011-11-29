class SubmissionPresenter
  ATTRIBUTES = [ :submission_id, :template_id, :study_name, :project_name, :lanes_of_sequencing_required, :comments, :order ]

  attr_accessor *ATTRIBUTES

  def initialize(user, submission_attributes = {})
    @user = user

    ATTRIBUTES.each do |attribute|
      send("#{attribute}=", submission_attributes[attribute])
    end

  end

  def build_submission!
    raise "NOT IMPLEMENTED YET"
  end

  def order
    @order ||= template.new_order(
      :project => project
    )
  end

  # These parameters should be defined by the submission template (to be renamed
  # order template) the old view code gets them by generating a new instance of
  # Order and then calling Order#input_field_infos.  This is a wrapper around
  # until I can refactor it out.
  def order_parameters
    order.input_field_infos
  end

  def project
    @project ||= Project.find_by_name(@project_name)
  end

  def project_valid?
    order.project_quotas_valid_for_submission?
  end

  # Creates a new submission and adds an initial order on the submission using
  # the parameters
  def save!
    ActiveRecord::Base.transaction do
      submission = Submission.create!(:user => @user)

      order = template.new_order(
        :study           => study,
        :project         => project,
        :user            => @user,
        :request_options => @order[:parameters],
        :submission      => submission,
        :comments        => comments
      )

      # Needs to support samples by name for Emma
      asset_group = AssetGroup.find(@order[:asset_group])
      order.update_attributes(:asset_group => asset_group)

      order.save!

    end
  end

  def study
    @study ||= Study.find_by_name(@study_name)
  end

  # Returns an array of the names of all the non-inactive studies
  def studies
    # @studies ||= Study.all.reject(&:inactive?).map(&:name)
    @studies ||= Study.all(:conditions => ["state != 'inactive'"]).map(&:name)
  end

  def submission
    @submission ||= Submission.find(@submission_id)
  end

  # Returns the SubmissionTemplate (OrderTemplate) to be used for this Submission.
  def template
    @template ||= SubmissionTemplate.find(@template_id)
  end

  def templates
    @templates ||= SubmissionTemplate.all
  end

  # Returns an array of all the names of studies associated with the current
  # user.
  def user_projects
    @user_projects ||= @user.sorted_project_names_and_ids.map(&:first)
  end
end




class SubmissionsController < ApplicationController

  def new
    @submission_presenter = SubmissionPresenter.new(current_user)
  end

  def create
    @submission_presenter = SubmissionPresenter.new(current_user, params[:submission])

    @submission_presenter.save!

    redirect_to :edit
  end


  ###################################################               AJAX ROUTES
  # TODO[sd9]: These AJAX routes could be refactored
  def project_details
    @submission_presenter = SubmissionPresenter.new(current_user, params[:submission])

    render :partial => 'project_details', :layout => false
  end

  def order_parameters
    @submission_presenter = SubmissionPresenter.new(current_user, params[:submission])

    render :partial => 'order_parameters', :layout => false
  end

  def study_assets
    @submission_presenter = SubmissionPresenter.new(current_user, params[:submission])

    render :partial => 'study_assets', :layout => false
  end
  ##################################################         End of AJAX ROUTES
end

