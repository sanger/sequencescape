require "rexml/document"

class StudiesController < ApplicationController
  include REXML
  include Informatics::Globals
  include XmlCacheHelper::ControllerHelper

  before_filter :login_required
  before_filter :admin_login_required, :only => [:new_plate_submission, :create_plate_submission, :settings, :administer, :manage, :managed_update, :grant_role, :remove_role]
  before_filter :manager_login_required, :only => [ :close, :open, :related_studies, :relate_study, :unrelate_study]

  around_filter :rescue_validation, :only => [:close, :open]

  def setup_studies_from_scope(exclude_nested_resource = false)
    if logged_in? and not exclude_nested_resource
      @alternatives = [
        "interesting", "followed", "managed & active", "managed & inactive",
        "pending", "pending ethical approval", "contaminated with human dna",
        "remove x and autosomes", "active", "inactive", "collaborations", "all"
      ]
      @studies = studies_from_scope(@alternatives[params[:scope].to_i])
    elsif params[:project_id] && !(project = Project.find(params[:project_id])).nil?
      @studies = project.studies(:include => [:user, :roles], :order => 'created_at desc')
    else
      @studies = Study.newest_first.with_user_included.with_related_users_included
    end
  end

  def index
    # Please do not user current_user outside this block, you kill the API calls
    setup_studies_from_scope(@exclude_nested_resource)
    respond_to do |format|
      format.html
      format.xml  { render(:action => (@exclude_nested_resource ? 'index' : 'index_deprecated_xml')) }
      format.json { render :json => Study.all.to_json }
    end
  end

  def study_list
    return redirect_to(studies_path) unless request.xhr?
    setup_studies_from_scope
    render :partial => "study_list", :locals => { :studies => @studies.with_related_users_included.all }
  end

  def new
    @study = Study.new
    respond_to do |format|
      format.html
    end
  end

  ## Create the Study from new with the details from its form.
  ## Redirect to the index page with a notice.
  def create
    ActiveRecord::Base.transaction do
      @study = Study.new(params['study'].merge(:user => current_user))
      @study.save!
      current_user.has_role('manager', @study)
      User.find(params[:study_owner_id]).has_role('owner', @study) unless params[:study_owner_id].blank?
    end

    flash[:notice] = "Your study has been created"
    respond_to do |format|
      format.html { redirect_to study_path(@study) }
      format.xml  { render :xml  => @study, :status => :created, :location => @study }
      format.json { render :json => @study, :status => :created, :location => @study }
    end
  rescue ActiveRecord::RecordInvalid => exception
    action_flash[:error] = "Problems creating your new study"
    respond_to do |format|
      format.html { render :action => "new" }
      format.xml  { render :xml  => @study.errors, :status => :unprocessable_entity }
      format.json { render :json => @study.errors, :status => :unprocessable_entity }
    end
  end

  def show
    @study = Study.find(params[:id])

    respond_to do |format|
      format.html do
        if current_user.workflow.nil?
          flash[:notice] = "Your profile is incomplete. Please select a workflow."
          redirect_to edit_profile_path(current_user)
        else
          redirect_to study_workflow_path(@study, current_user.workflow)
        end
      end
      format.xml { cache_xml_response(@study) }
      format.json { render :json => @study.to_json }
    end
  end

  def edit
    @study = Study.find(params[:id])
    @users   = User.all
    redirect_if_not_owner_or_admin
  end

  def update
    @study = Study.find(params[:id])
    redirect_if_not_owner_or_admin

    ActiveRecord::Base.transaction do
      @study.update_attributes!(params[:study])
      unless params[:study_owner_id].blank?
        owner = User.find(params[:study_owner_id])
        unless owner.is_owner?(@study)
          @study.owners.first.has_no_role('owner', @study) if @study.owners.size == 1
          owner.has_role('owner', @study)
        end
      end

      flash[:notice] = "Your study has been updated"

      redirect_to study_path(@study)
    end
  rescue ActiveRecord::RecordInvalid => exception
    logger.warn "Failed to update attributes: #{@study.errors.map {|e| e.to_s }}"
    flash[:error] = "Failed to update attributes for study!"
    render :action => "edit", :id => @study.id
  end

  def destroy
    study = Study.find(params[:id])
    if study.destroy
      flash[:notice] = "Study deleted."
    else
      flash[:error] = "Failed to destroy study!"
    end
    redirect_to studies_path
  end

  def study_status
    @study = Study.find(params[:id])
    redirect_if_not_owner_or_admin

    if @study.inactive? || @study.pending?
      @study.activate!
    elsif @study.active?
      @study.deactivate!
    end
    flash[:notice] = "Study status was updated successfully"
    redirect_to study_path(@study)
  end

  def assembly
    @study = Study.find(params[:id])
    if params[:assembly]
      unless @study.add_reference(params)
        flash[:error] = "Failed to attach reference sequence"
      else
        redirect_to study_path(@study)
      end
    end
  end

  def properties
    @study = Study.find(params[:id])

    respond_to do |format|
      format.html
      format.xml
      format.json { render :json => @study.to_json }
    end
  end

  def collaborators
    @study    = Study.find(params[:id])
    @all_roles  = Role.all(:select => " distinct `name`")
    @roles      = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
    @users      = User.all(:order => :first_name)
  end

  def related_studies
    @study    = Study.find(params[:id])
    @relation_names = StudyRelationType::names
    @studies = current_user.interesting_studies
    @studies.delete(@study)

    #TODO create a proper ReversedStudyRelation
    @relations = @study.study_relations.map { |r| [r.related_study, r.name ] } +
      @study.reversed_study_relations.map { |r| [r.study, r.reversed_name ] }

  end


  def update_study_relation
    @study = Study.find(params[:id])
    status = 500

    if pr=params[:related_study]
      relation_type_name    = pr[:relation_type]
      related_study = Study.find_by_id pr[:study_id]

      begin
        yield(relation_type_name, related_study)
        redirect_to :action =>  "related_studies"
        return
      rescue ActiveRecord::RecordInvalid, RuntimeError => ex
        status = 403
        action_flash[:error] = ex.to_s
      end

    else
      action_flash[:error] = "A problem occurred while relating the study"
      status = 500
    end
    @study.reload
    related_studies
    render :action => :related_studies, :status => status
  end

  def relate_study
    update_study_relation do |relation_type_name, related_study|
        StudyRelationType::relate_studies_by_name!(relation_type_name, @study, related_study)
        flash[:notice] = "Relation added"
    end
  end

  def unrelate_study
    update_study_relation do |relation_type_name, related_study|
        StudyRelationType::unrelate_studies_by_name!(relation_type_name, @study, related_study)
        flash[:notice] = "Relation removed"
    end
  end

  def follow
    @study    = Study.find(params[:id])
    if current_user.has_role? 'follower', @study
      current_user.has_no_role 'follower', @study
      flash[:notice] = "You have stopped following the '#{@study.name}' study."
    else
      current_user.has_role 'follower', @study
      flash[:notice] = "You are now following the '#{@study.name}' study."
    end
    redirect_to study_workflow_path(@study, current_user.workflow)
  end

  def choice
    if params[:id]
      kind = params[:id]
      @curated_references = Sequence.curated_sequences
      render :partial => "studies/sequences/" +kind.downcase
    else
      render :nothing => true
    end
  end

  def close
     @study = Study.find(params[:id])
     @study.deactivate!
     @study.save
     flash[:notice] = "This study has been deactivated"
     redirect_to study_path(@study)
   end

   def open
     @study = Study.find(params[:id])
     @study.activate!
     @study.save
     flash[:notice] = "This study has been activated"
     redirect_to study_path(@study)
   end

   def show_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      xml_text =@study.accession_service.accession_study_xml(@study)
      format.xml  { render(:text => xml_text) }
    end
   end

   def show_policy_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      xml_text =@study.accession_service.accession_policy_xml(@study)
      format.xml  { render(:text => xml_text) }
    end
   end

   def show_dac_accession
    @study = Study.find(params[:id])
    respond_to do |format|
      xml_text =@study.accession_service.accession_dac_xml(@study)
      format.xml  { render(:text => xml_text) }
    end
   end

   def rescue_accession_errors
     yield
   rescue ActiveRecord::RecordInvalid => exception
     flash[:error] = 'Please fill in the required fields'
     render(:action => :edit)
   rescue AccessionService::NumberNotRequired => exception
     flash[:warning] = 'An accession number is not required for this study'
     redirect_to(study_path(@study))
   rescue AccessionService::NumberNotGenerated => exception
     flash[:warning] = 'No accession number was generated'
     redirect_to(study_path(@study))
   rescue AccessionService::AccessionServiceError => exception
     flash[:error] = exception.message
     redirect_to(edit_study_path(@study))
   end
   def accession
     rescue_accession_errors do
       @study = Study.find(params[:id])
       @study.validate_ena_required_fields!
       @study.accession_service.submit_study_for_user(@study, current_user)

       flash[:notice] = "Accession number generated: #{ @study.ebi_accession_number }"
       redirect_to(study_path(@study))
     end
   end

   def dac_accession
     rescue_accession_errors do
       @study = Study.find(params[:id])
       @study.accession_service.submit_dac_for_user(@study, current_user)

       flash[:notice] = "Accession number generated: #{ @study.dac_accession_number }"
       redirect_to(study_path(@study))
     end
   end

   def policy_accession
     rescue_accession_errors do
       @study = Study.find(params[:id])
       @study.accession_service.submit_policy_for_user(@study, current_user)

       flash[:notice] = "Accession number generated: #{ @study.policy_accession_number }"
       redirect_to(study_path(@study))
       end
   end

   def sra
     @study = Study.find(params[:id])
   end

   def state
     @study = Study.find(params[:id])
   end

   def new_plate_submission
     @study = Study.find(params[:id])
   end

   def create_plate_submission
     @study = Study.find(params[:id])
     @project = Project.find(params[:studies][:project])

     plates = []
     params[:studies][:barcodes].scan(/\d+/).each do |plate_barcode|
       plate = Plate.find_by_barcode(plate_barcode)
       unless plate.nil?
         plates << plate
       else
         @study.errors.add("Plate", "Couldnt find plate #{plate_barcode}")
       end
     end

     if @study.errors.count > 0
       flash[:error] = "Error submitting your plates"
       respond_to do |format|
         format.html { render :action => "new_plate_submission"}
         format.xml  { render :xml  => flash, :status => :unprocessable_entity }
         format.json { render :json => flash, :status => :unprocessable_entity }
       end
       return
     else
       Plate.create_plates_submission(@project, @study, plates, current_user)
     end

     if @study.errors.count > 0
       flash[:error] = "Error submitting your plates"
       respond_to do |format|
         format.html { render :action => "new_plate_submission"}
         format.xml  { render :xml  => flash, :status => :unprocessable_entity }
         format.json { render :json => flash, :status => :unprocessable_entity }
       end
     else
       flash[:notice] = "Your plates have been submitted"
       respond_to do |format|
         format.html { render :action => "new_plate_submission" }
         format.xml  { render :xml  => @study, :status => :created, :location => @study }
         format.json { render :json => @study, :status => :created, :location => @study }
       end
     end
   end

   def grant_role
     @user    = User.find(params[:role][:user])
     @study = Study.find(params[:id])
     @role    = Role.find_by_name(params[:role][:authorizable_type])

     if request.xhr?
       if params[:role]
         @user.has_role(params[:role][:authorizable_type].to_s, @study)
         @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
         flash[:notice] = "Role added"
         render :partial => "roles", :status => 200
       else
         @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
         flash[:error] = "A problem occurred while adding the role"
         render :partial => "roles", :status => 500
       end
     else
       @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
       flash[:error] = "A problem occurred while adding the role"
       render :partial => "roles", :status => 401
     end
   end

   def remove_role
     @user    = User.find(params[:role][:user])
     @study = Study.find(params[:id])
     @role    = Role.find_by_name(params[:role][:authorizable_type])

     if request.xhr?
       if params[:role]
         @user.has_no_role(params[:role][:authorizable_type].to_s, @study)
         @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
         flash[:error] = "Role was removed"
         render :partial => "roles", :status => 200
       else
         @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
         flash[:error] = "A problem occurred while removing the role"
         render :partial => "roles", :status => 500
       end
     else
       @roles   = Role.find(:all, :conditions => {:authorizable_id => @study.id, :authorizable_type => "Study"})
       flash[:error] = "A problem occurred while removing the role"
       render :partial => "roles", :status => 401
     end
   end

   def projects
     @study = Study.find(params[:id])
     @projects = @study.projects.paginate :page => params[:page]
   end

   def sample_manifests
     @study = Study.find(params[:id])
     @sample_manifests = @study.sample_manifests.paginate(:page => params[:page])
   end

   def suppliers
     @study = Study.find(params[:id])
     @suppliers = @study.suppliers.paginate(:page => params[:page])
   end

   def study_reports
     @study = Study.find(params[:id])
     @study_reports = StudyReport.without_files.for_study(@study).paginate(:page => params[:page], :order => 'id DESC')
   end


  private

  def redirect_if_not_owner_or_admin
    unless current_user.owner?(@study) or current_user.is_administrator? or current_user.is_manager?
      flash[:error] = "Study details can only be altered by the owner (#{@study.user.login}) or an administrator or manager"
      redirect_to study_path(@study)
    end
  end

  def studies_from_scope(scope)
    studies = case scope
    when "interesting"                 then Study.of_interest_to(current_user)
    when "followed"                    then Study.followed_by(current_user)
    when "managed & active"            then Study.managed_by(current_user).is_active
    when "managed & inactive"          then Study.managed_by(current_user).is_inactive
    when "pending"                     then Study.is_pending
    when "pending ethical approval"    then Study.all_awaiting_ethical_approval
    when "contaminated with human dna" then Study.all_contaminated_with_human_dna
    when "remove x and autosomes"      then Study.all_with_remove_x_and_autosomes
    when "active"                      then Study.is_active
    when "inactive"                    then Study.is_inactive
    when "collaborations"              then Study.collaborated_with(current_user)
    when "all"                         then Study
    else                               raise StandardError, "Unknown scope '#{ scope }'" # Study.of_interest_to(current_user)
    end

    return studies.newest_first
  end

  def rescue_validation
    begin
      yield
    rescue ActiveRecord::RecordInvalid
      logger.warn "Failed to update attributes: #{@study.errors.map {|e| e.to_s }}"
      flash[:error] = "Failed to update attributes for study!"
      render :action => "edit", :id => @study.id
    end
  end
end
