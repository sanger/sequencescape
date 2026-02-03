# frozen_string_literal: true
require 'rexml/document'

# rubocop:todo Metrics/ClassLength
class StudiesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  include REXML
  include Informatics::Globals
  include ::AccessionHelper

  before_action :login_required
  authorize_resource only: %i[grant_role remove_role update edit]

  around_action :rescue_validation, only: %i[close open]

  def setup_studies_from_scope(exclude_nested_resource = false) # rubocop:todo Metrics/AbcSize
    if logged_in? && (not exclude_nested_resource)
      @alternatives = [
        'interesting',
        'followed',
        'managed & active',
        'managed & inactive',
        'pending',
        'pending ethical approval',
        'contaminated with human dna',
        'remove x and autosomes',
        'active',
        'inactive',
        'collaborations',
        'all'
      ]
      @studies = studies_from_scope(@alternatives[params[:scope].to_i])
    elsif params[:project_id] && !(project = Project.find(params[:project_id])).nil?
      @studies = project.studies.newest_first.includes(:user, :roles)
    else
      @studies = Study.newest_first.with_user_included.with_related_users_included
    end
  end

  def index
    # Please do not user current_user outside this block, you kill the API calls
    setup_studies_from_scope(@exclude_nested_resource)
    respond_to do |format|
      format.html
      format.xml { render(action: (@exclude_nested_resource ? 'index' : 'index_deprecated_xml')) }
      format.json { render json: Study.all.to_json }
    end
  end

  def study_list
    return redirect_to(studies_path) unless request.xhr?

    setup_studies_from_scope
    render partial: 'study_list', locals: { studies: @studies.with_related_owners_included }
  end

  def show
    @study = Study.find(params[:id])
    flash.keep
    respond_to do |format|
      format.html { redirect_to study_information_path(@study) }
      format.xml { render layout: false }
      format.json { render json: @study.to_json }
    end
  end

  def new
    @study = Study.new
    respond_to { |format| format.html }
  end

  def edit
    @study = Study.find(params[:id])
    flash.now[:warning] = @study.warnings if @study.warnings.present?
    @users = User.all
  end

  ## Create the Study from new with the details from its form.
  ## Redirect to the index page with a notice.
  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    ActiveRecord::Base.transaction do
      @study = Study.new(params['study'].merge(user: current_user))
      @study.save!
      current_user.grant_manager(@study)
      User.find(params[:study_owner_id]).grant_owner(@study) if params[:study_owner_id].present?
    end

    flash[:notice] = 'Your study has been created'
    respond_to do |format|
      format.html { redirect_to study_path(@study) }
      format.xml { render xml: @study, status: :created, location: @study }
      format.json { render json: @study, status: :created, location: @study }
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = 'Problems creating your new study'
    respond_to do |format|
      format.html { render action: 'new' }
      format.xml { render xml: @study.errors, status: :unprocessable_entity }
      format.json { render json: @study.errors, status: :unprocessable_entity }
    end
  end

  # rubocop:todo Metrics/MethodLength
  def update # rubocop:todo Metrics/AbcSize
    @study = Study.find(params[:id])

    ActiveRecord::Base.transaction do
      @study.update!(params[:study])
      if params[:study_owner_id].present?
        owner = User.find(params[:study_owner_id])
        unless owner.owner_of?(@study)
          @study.owners.first.remove_role('owner', @study) if @study.owners.size == 1
          owner.grant_owner(@study)
        end
      end

      flash[:notice] = 'Your study has been updated'

      redirect_to study_path(@study)
    end
  rescue ActiveRecord::RecordInvalid => e
    # don't use @study.errors.map(&:to_s) because it throws an exception when within a rescue block
    Rails.logger.warn "Failed to update attributes: #{@study.errors.map { |error| error.to_s }}" # rubocop:disable Style/SymbolProc
    flash.now[:error] = 'Failed to update attributes for study!'
    render action: 'edit', id: @study.id
  end

  # rubocop:enable Metrics/MethodLength

  def study_status
    @study = Study.find(params[:id])
    authorize! :activate, @study

    if @study.inactive? || @study.pending?
      @study.activate!
    elsif @study.active?
      @study.deactivate!
    end
    flash[:notice] = 'Study status was updated successfully'
    redirect_to study_path(@study)
  end

  def properties
    @study = Study.find(params[:id])

    respond_to do |format|
      format.html
      format.xml
      format.json { render json: @study.to_json }
    end
  end

  def collaborators
    @study = Study.find(params[:id])
    @all_roles = Role.distinct.pluck(:name)
    @roles = Role.where(authorizable_id: @study.id, authorizable_type: 'Study')
    @users = User.order(:first_name)
  end

  def follow # rubocop:todo Metrics/AbcSize
    @study = Study.find(params[:id])
    if current_user.follower_of?(@study)
      current_user.remove_role 'follower', @study
      flash[:notice] = "You have stopped following the '#{@study.name}' study."
    else
      current_user.grant_follower(@study)
      flash[:notice] = "You are now following the '#{@study.name}' study."
    end
    redirect_to study_information_path(@study)
  end

  def close
    @study = Study.find(params[:id])
    authorize! :activate, @study
    comment = params[:comment]
    @study.comments.create(description: comment, user_id: current_user.id)
    @study.deactivate!
    @study.save
    flash[:notice] = "This study has been deactivated: #{comment}"
    redirect_to study_path(@study)
  end

  def open
    @study = Study.find(params[:id])
    authorize! :activate, @study
    @study.activate!
    @study.save
    flash[:notice] = 'This study has been activated'
    redirect_to study_path(@study)
  end

  def show_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      accession_service = AccessionService.select_for_study(@study)
      xml_text = accession_service.accession_study_xml(@study)
      format.xml { render(xml: xml_text) }
    end
  end

  def show_policy_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      accession_service = AccessionService.select_for_study(@study)
      xml_text = accession_service.accession_policy_xml(@study)
      format.xml { render(xml: xml_text) }
    end
  end

  def show_dac_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      accession_service = AccessionService.select_for_study(@study)
      xml_text = accession_service.accession_dac_xml(@study)
      format.xml { render(xml: xml_text) }
    end
  end

  def rescue_accession_errors # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    yield
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = 'Please fill in the required fields'
    render(action: :edit)
  rescue AccessionService::NumberNotRequired => e
    flash[:warning] = e.message || 'An accession number is not required for this study'
    redirect_to(study_path(@study))
  rescue AccessionService::NumberNotGenerated => e
    flash[:warning] = "No accession number was generated: #{e.message}"
    redirect_to(study_path(@study))
  rescue AccessionService::AccessionServiceError => e
    flash[:error] = e.message
    redirect_to(edit_study_path(@study))
  end

  def accession # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @study = Study.find(params[:id])

    unless accessioning_enabled?
      flash[:warning] = 'Accessioning is not enabled in this environment.'
      return redirect_to(study_path(@study))
    end
    # TODO: Y26-026 - Enforce accessioning permissions
    # unless permitted_to_accession?(@study)
    #   flash[:error] = 'Permission required to accession this study'
    #   return redirect_to(study_path(@study))
    # end

    rescue_accession_errors do
      @study.validate_study_for_accessioning!
      accession_service = AccessionService.select_for_study(@study)
      accession_service.submit_study_for_user(@study, current_user)

      flash[:notice] = "Accession number generated: #{@study.ebi_accession_number}"
      redirect_to(study_path(@study))
    end
  end

  def accession_all_samples # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @study = Study.find(params[:id])

    unless accessioning_enabled?
      flash[:warning] = 'Accessioning is not enabled in this environment.'
      return redirect_to(study_path(@study))
    end
    # TODO: Y26-026 - Enforce accessioning permissions
    # unless permitted_to_accession?(@study)
    #   flash[:error] = 'Permission required to accession this study'
    #   return redirect_to(study_path(@study))
    # end

    @study.accession_all_samples(current_user)

    if @study.errors.any?
      error_messages = compile_accession_errors(@study.errors)
      flash[:error] = error_messages
    else
      flash[:notice] = 'All of the samples in this study have been sent for accessioning. ' \
                       'Please check back in 5 minutes to confirm that accessioning was successful.'
    end
    redirect_to(study_path(@study, anchor: 'accession-statuses'))
  end

  def dac_accession
    @study = Study.find(params[:id])

    unless accessioning_enabled?
      flash[:warning] = 'Accessioning is not enabled in this environment.'
      return redirect_to(study_path(@study))
    end
    # TODO: Y26-026 - Enforce accessioning permissions
    # unless permitted_to_accession?(@study)
    #   flash[:error] = 'Permission required to accession this study'
    #   return redirect_to(study_path(@study))
    # end

    rescue_accession_errors do
      accession_service = AccessionService.select_for_study(@study)
      accession_service.submit_dac_for_user(@study, current_user)

      flash[:notice] = "Accession number generated: #{@study.dac_accession_number}"
      redirect_to(study_path(@study))
    end
  end

  def policy_accession
    @study = Study.find(params[:id])

    unless accessioning_enabled?
      flash[:warning] = 'Accessioning is not enabled in this environment.'
      return redirect_to(study_path(@study))
    end
    # TODO: Y26-026 - Enforce accessioning permissions
    # unless permitted_to_accession?(@study)
    #   flash[:error] = 'Permission required to accession this study'
    #   return redirect_to(study_path(@study))
    # end

    rescue_accession_errors do
      accession_service = AccessionService.select_for_study(@study)
      accession_service.submit_policy_for_user(@study, current_user)

      flash[:notice] = "Accession number generated: #{@study.policy_accession_number}"
      redirect_to(study_path(@study))
    end
  end

  def sra
    @study = Study.find(params[:id])
  end

  def state
    @study = Study.find(params[:id])
  end

  # rubocop:todo Metrics/MethodLength
  def self.role_helper(name, success_action, error_action) # rubocop:todo Metrics/AbcSize
    define_method(:"#{name}_role") do
      ActiveRecord::Base.transaction do
        @study = Study.find(params[:id])
        @user = User.find(params.require(:role).fetch(:user))

        if request.xhr?
          yield(@user, @study, params[:role][:authorizable_type].to_s)
          status, flash.now[:notice] = 200, "Role #{success_action}"
        else
          status, flash.now[:error] = 401, "A problem occurred while #{error_action} the role"
        end

        @roles = @study.roles.reload
        render partial: 'roles', status: status
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  role_helper(:grant, 'added', 'adding') { |user, study, name| user.grant_role(name, study) }
  role_helper(:remove, 'remove', 'removing') { |user, study, name| user.remove_role(name, study) }

  def projects
    @study = Study.find(params[:id])
    @projects = @study.projects.page(params[:page])
  end

  def sample_manifests
    @study = Study.find(params[:id])
    @sample_manifests = @study.sample_manifests.page(params[:page]).order(id: :desc)
  end

  def suppliers
    @study = Study.find(params[:id])
    @suppliers = @study.suppliers.page(params[:page])
  end

  def study_reports
    @study = Study.find(params[:id])
    @study_reports = StudyReport.for_study(@study).page(params[:page]).order(id: :desc)
  end

  private

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def studies_from_scope(scope) # rubocop:todo Metrics/CyclomaticComplexity
    studies =
      case scope
      when 'interesting'
        Study.of_interest_to(current_user)
      when 'followed'
        Study.followed_by(current_user)
      when 'managed & active'
        Study.managed_by(current_user).is_active
      when 'managed & inactive'
        Study.managed_by(current_user).is_inactive
      when 'pending'
        Study.is_pending
      when 'pending ethical approval'
        Study.awaiting_ethical_approval
      when 'contaminated with human dna'
        Study.contaminated_with_human_dna
      when 'remove x and autosomes'
        Study.with_remove_x_and_autosomes
      when 'active'
        Study.is_active
      when 'inactive'
        Study.is_inactive
      when 'collaborations'
        Study.collaborated_with(current_user)
      when 'all'
        Study
      else
        raise StandardError, "Unknown scope '#{scope}'"
      end
    studies.newest_first
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def rescue_validation
    yield
  rescue ActiveRecord::RecordInvalid
    Rails.logger.warn "Failed to update attributes: #{@study.errors.map { |error| error.to_s }}" # rubocop:disable Style/SymbolProc
    flash.now[:error] = 'Failed to update attributes for study!'
    render action: 'edit', id: @study.id
  end

  def compile_accession_errors(errors, max_messages = 6)
    error_messages = ['The samples in this study could not be accessioned, please check the following errors:']
    error_messages.concat(errors.full_messages.first(max_messages))

    return error_messages unless errors.size > max_messages

    error_messages << '...'
    error_messages << "Only the first #{max_messages} of #{errors.size} errors are shown."
  end
end
# rubocop:enable Metrics/ClassLength
