# frozen_string_literal: true

# The submission controller handles the AJAXy submission form, not bulk submissions
# The typical submission creation process is actually handled by a series of requests,
# such as the fields that get displayed when a submission template is selected, and
# the creation of each independent order.
# Most the actual heavy lifting occurs in {Submission::SubmissionCreator}
class SubmissionsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  authorize_resource

  after_action :set_cache_disabled!, only: %i[new index]

  #
  # Displays a list of submissions for the current user.
  # building => Submissions which haven't yet been queued for building and may still be edited. Submissions begin in
  # this state, and leave when the user clicks 'Build Submission'
  # pending  => Submissions which the user has finished setting up, and has queued for processing by the delayed job
  # ready    => Submissions which the delayed job has finished processing. The final state of a submission.
  def index # rubocop:todo Metrics/AbcSize
    # Disable cache of this page
    expires_now

    @building = Submission.building.order(created_at: :desc).where(user_id: current_user.id)
    @pending = Submission.pending.order(created_at: :desc).where(user_id: current_user.id)
    @ready = Submission.ready.order(created_at: :desc).limit(10).where(user_id: current_user.id)
  end

  # Show a submission. Read-only page, but provides a link to the edit page for submissions which
  # haven't yet left state building
  def show
    @presenter = Submission::SubmissionPresenter.new(current_user, id: params[:id])
  end

  # The main landing page for creating a new submission. Lots of ajax action!
  def new
    expires_now
    @presenter = Submission::SubmissionCreator.new(current_user, study_id: params[:study_id])
  end

  def edit
    @presenter = Submission::SubmissionCreator.new(current_user, id: params[:id])
  end

  # Triggered when someone clicks 'Save Order' in the submission creator
  # New Order is just client side
  # Creates an order, followed by a submission, and then assigns the order to the submission.
  # On subsequent clicks of 'Save Order' we pass in the submission id from the original
  def create
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission].to_unsafe_h)

    if @presenter.save
      render partial: 'saved_order',
             locals: {
               presenter: @presenter,
               order: @presenter.order,
               form: :dummy_form_symbol
             },
             layout: false
    else
      render partial: 'order_errors', layout: false, status: :unprocessable_entity
    end
  end

  # This method will build a submission then redirect to the submission on completion
  def update
    @presenter = Submission::SubmissionCreator.new(current_user, id: params[:id])

    @presenter.build_submission!

    if @presenter.submission.errors.present?
      flash[:error] = "The submission could not be built: #{@presenter.submission.errors.full_messages}"
    end

    redirect_to @presenter.submission
  end

  def change_priority
    Submission.find(params[:id]).update!(priority: params[:submission][:priority])
    redirect_to action: :show, id: params[:id]
  end

  # Cancels the selected submission, and returns the user to the submission show page.
  # Cancelled submissions in turn cancel all their requests.
  # Only cancellable submissions can be cancelled. (There shouldn't be a link if they can't be cancelled)
  # but it might be nice to add a bit more user friendly error handling here.
  def cancel
    submission = Submission.find(params[:id])
    submission.cancel!
    redirect_to action: :show, id: params[:id]
  end

  # Submissions can only be destroyed when they are still building.
  def destroy
    ActiveRecord::Base.transaction do
      submission = Submission::SubmissionPresenter.new(current_user, id: params[:id])
      if submission.destroy
        flash[:notice] = 'Submission successfully deleted!'
      else
        flash[:error] = "This submission can't be deleted"
      end
      redirect_to action: :index
    end
  end

  # An index page for study submissions.
  # Bit unconventional URL eg:
  # http://localhost:3000/submissions/study?id=23
  # Rather than http://localhost:3000/studies/23/submissions
  def study
    @study = Study.find(params[:id])
    @submissions = @study.submissions
  end

  def download_scrna_core_cdna_pooling_plan
    csv_string = ''
    send_data csv_string, type: 'text/plain', filename: "#{params[:id]}_scrna_core_cdna_pooling_plan.csv",
                          disposition: 'attachment'
  end

  ###################################################               AJAX ROUTES
  # TODO[sd9]: These AJAX routes could be re-factored

  # AJAXY route for rendering the submission level options which appear upon
  # selecting a submission template.
  def order_fields
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission])

    render partial: 'order_fields', layout: false
  end

  # AJAXY route to populate study asset group dropdown
  def study_assets
    @presenter = Submission::SubmissionCreator.new(current_user, params[:submission])

    render partial: 'study_assets', layout: false
  end
  ##################################################         End of AJAX ROUTES
end
