class Studies::Workflows::SubmissionsController < ApplicationController
  SubmissionsControllerError = Class.new(StandardError)
  IncorrectParamsException   = Class.new(SubmissionsControllerError)
  InvalidInputException      = Class.new(SubmissionsControllerError)
  
  def show
    @study         = Study.find(params[:study_id]) if params[:study_id]
    @workflow        = Submission::Workflow.find(params[:workflow_id]) if params[:workflow_id]
    @submission      = Submission.find(params[:id])
    @assets          = []
    @request_types   = []

    @study ||= @submission.order.study unless @study
    @workflow ||= @submission.order.workflow 

    @submission_template_id = params[:submission_template_id] || if @submission && @submission.order
      template = SubmissionTemplate.find_by_name(@submission.order.template_name)
      template && template.id
    end
  end

  def index
    @study         = Study.find(params[:study_id])
    @workflow        = Submission::Workflow.find(params[:workflow_id])
    @submissions     = @study.submissions
  end

  def new
    catch :end do
      @workflow       = Submission::Workflow.find(params[:workflow_id])
      @study          = Study.find(params[:study_id])     
      if @study.inactive? # || @study.pending?
        flash[:error] = "Study '#{@study.name}' is inactive, no submissions can be added"
        redirect_to studies_url
        return
      end

      template_id= params[:submission_template_id]
      @submission_template = SubmissionTemplate.find_by_id(template_id)
      if @submission_template.nil?
        flash[:error] = "Invalid or missing template id"
        redirect_to template_chooser_study_workflow_submissions_path(@study, @workflow)
        throw :end
      end
      @submission = @submission_template.new_submission 


      options = {}
      options["workflow_id"] = params[:workflow_id]

      # temporary hack to make properties not filtered if we are in the wrong forklow
      current_user.workflow = @workflow

      if current_user.projects.empty?
        flash[:error] = "You do not manage any financial projects.  Please create one or ask an administrator to assign you as manager to a project."
      end

      if !@study.approved? && !flash[:error]
        flash[:notice] = "Your study is not yet approved. You will be unable to submit requests until it is."
      end
    end #:end
  end

  def set_variables_for_create
    @workflow = Submission::Workflow.find(params[:workflow_id])
    @study    = Study.find(params[:study_id])
    @comments = nil

    # NOTE[xxx]: Quick hack to get this working for the features and into production.  Basically lookup by ID if the project
    # project name was not specified and the project_id is specified.  Should handle the Ajax stuff.
    @project   = Project.find_by_name(params[:project_name])  if params[:project_name].present?
    @project ||= Project.find_by_id(params[:project_id]) if params[:project_id].present?
  end

  def find_by_name(klass, text)
      names = text.lines.map(&:chomp).reject { |l| l.blank? }
      names = names.map{ |n| n.strip }
      objects = klass.find(:all, :conditions => {:name => names})
      name_set = Set.new(names)
      find_set = Set.new(objects.map(&:name))
      not_found = name_set - find_set
      raise InvalidInputException, "#{klass.table_name} #{not_found.to_a.join(", ")} not founds" unless not_found.empty?
      return objects
  end
  
  def find_sample_by_name_or_sanger_sample_id( text)
    names = text.lines.map(&:chomp).reject(&:blank?).map(&:strip)

    objects = Sample.all(:include => :assets, :conditions => [ 'name IN (:names) OR sanger_sample_id IN (:names)', { :names => names } ])

    name_set  = Set.new(names)
    found_set = Set.new(objects.map { |s| [ s.name, s.sanger_sample_id ] }.flatten)
    not_found = name_set - found_set
    raise InvalidInputException, "#{Sample.table_name} #{not_found.to_a.join(", ")} not founds" unless not_found.empty?
    return objects
  end

  #--
  # NOTE[xxx]: The view says 'OR' but the code originally did 'AND', so I changed it!
  #++
  def asset_source_details_from_request_parameters
    # Raise an error if someone tries to do multiple things all at once!
    input_choice = [ :asset_group, :asset_ids, :asset_names, :sample_names ].select { |k| not params[k].blank? }
    raise InvalidInputException, "No assets found" if input_choice.empty?
    raise InvalidInputException, "Cannot handle choosing multiple asset sources" unless input_choice.size == 1

    return case input_choice.first
    when :asset_group then { :asset_group => AssetGroup.find(params[:asset_group]) }
    when :asset_ids   then { :assets => Asset.find_all_by_id(params[:asset_ids].split).uniq }
    when :asset_names then { :assets => find_by_name(Asset, params[:asset_names]) }
    when :sample_names 
      asset_lookup_method = params[:plate_purpose_id].blank? ? :assets_of_request_type_for : :wells_on_specified_plate_purpose_for
      { :assets => send(asset_lookup_method, find_sample_by_name_or_sanger_sample_id(params[:sample_names])) }

    else raise StandardError, "No way to determine assets for input choice #{input_choice.first.inspect}"
    end
  end
  private :asset_source_details_from_request_parameters

  def wells_on_specified_plate_purpose_for(samples)
    plate_purpose = PlatePurpose.find(params[:plate_purpose_id])
    samples.map do |sample|
      sample.wells.all(:include => :plate).detect { |well| well.plate.plate_purpose_id == plate_purpose.id } or
        raise InvalidInputException, "No #{plate_purpose.name} plate has sample #{sample.name}"
    end
  end
  private :wells_on_specified_plate_purpose_for

  def assets_of_request_type_for(samples)
    request_type     = @request_type_ids.size >= 1 ? RequestType.find(@request_type_ids.first) : nil
    asset_type_class = (request_type.try(:asset_type) || 'Asset').constantize
    samples.map do |sample|
      sample.assets.of_type(asset_type_class).first or
        raise InvalidInputException, "No #{asset_type_class.name.downcase} found for sample #{sample.name}"
    end
  end
  private :assets_of_request_type_for

  # The request_type parameter is intended to be an array, so we need to convert the numerically keyed hash
  # to an actual array.
  before_filter :request_type_from_hash_to_array, :only => :create

  def request_type_from_hash_to_array
    return if params[:request_type].blank?
    return if params[:request_type].is_a?(Array)    # BUG: Rails appears to call this filter twice, at least in tests

    params[:request_type] = params[:request_type].inject([]) do |array,(key, value)|
      array.tap { array[key.to_i] = value }
    end 
  end
  private :request_type_from_hash_to_array

  def create
    set_variables_for_create
    template_id= params[:submission_template_id]
    @submission_template = SubmissionTemplate.find_by_id(template_id)
    if @submission_template.nil?
      flash[:error] = "Invalid template id"
      redirect_to template_chooser_study_workflow_submissions_path(@study, @workflow)
      return
    end

    params[:user_id] = current_user.id

    respond_to do |format|
      begin
        request_type_multiplier = {}

        if params[:request_type]
          @request_type_ids = []
          params[:request_type].each do |details|
            @request_type_ids << details[:request_type_id]
            request_type_multiplier[details[:request_type_id].to_i] = details[:number].to_i unless details[:number].blank?
          end
        end

        asset_details = asset_source_details_from_request_parameters
        @comments = params[:submission][:comments] if params[:submission][:comments]
        @properties = params.fetch(:request, {}).fetch(:properties, {})
        @properties[:multiplier] = request_type_multiplier unless request_type_multiplier.empty?

        # Written in app/models/submission.rb and no idea why it was in that file
        # there is no way to differentiate betwween an empti array and an empty hash in she controller paramters, so the controller can send us an empty array
        @properties = {} if @properties == []

        @submission = Submission.build!(
          {:template        => @submission_template,
          :study           => @study,
          :project         => @project,
          :workflow        => @workflow,
          :user            => current_user,
          :request_types   => @request_type_ids,
          :request_options => @properties,
          :comments        => @comments}.merge(asset_details)
        )

        flash[:notice] = "Submission successfully created"
        format.html { redirect_to study_workflow_submission_path(@study, @workflow, @submission) }
      rescue QuotaException => quota_exception
        action_flash[:error] = quota_exception.message
        raise
      rescue InvalidInputException => input_exception
        action_flash[:error] = input_exception.message
        raise
      rescue IncorrectParamsException => exception
        action_flash[:error] = exception.message
        raise
      rescue ActiveRecord::RecordInvalid => exception
        action_flash[:error] = exception.record.errors.full_messages.join(', ')
        raise
      end
    end
  rescue StandardError, QuotaException => exception
    return render(:action => 'new')
  end

  def destroy
    @submission = Submission.find(params[:id])
    @study = @submission.study
    @workflow = @submission.workflow
    # Checks if anything is not pending
    unless @submission.safe_to_delete?
      flash[:error] = "You can not delete a submission that has started"
      redirect_to study_workflow_path(@study, @workflow)
    else
      @submission.destroy
      flash[:notice] = "Successfully deleted submission #{@submission.id} and related data"
      @study.events.create(
        :message => "Submission #{@submission.id} and all related data was deleted",
        :created_by => current_user.login,
        :content => "",
        :of_interest_to => "administrators"
      )
      redirect_to study_workflow_path(@study, @workflow)
    end
  end

  def template_chooser
    @study         = Study.find(params[:study_id])
    @workflow = Submission::Workflow.find(params[:workflow_id])
    @template_list = SubmissionTemplate.all
  end

  def info

    @workflow = Submission::Workflow.find(params[:workflow_id])
    @study = Study.find(params[:study_id])
    submission_template_id = params[:submission_template_id]
    if submission_template_id
      @submission_template = SubmissionTemplate.find(submission_template_id)
    else
      redirect_to new_study_workflow_submissions_path(@study, @workflow, :submission_template_id => submission_template_id)
      return
    end

    @submission = @submission_template.new_submission
    if @submission.info_differential.nil?
      redirect_to new_study_workflow_submission_path(@study, @workflow, :submission_template_id => submission_template_id)
      return
    end
  end
end
