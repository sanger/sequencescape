class SamplesController < ApplicationController
  include XmlCacheHelper::ControllerHelper

  require 'curb'

  before_filter :admin_login_required, :only => [ :administer, :destroy ]

  def index
    @samples = Sample.paginate :page => params[:page], :order => 'created_at DESC'
    respond_to do |format|
      format.html
      format.xml
      format.json { render :json => Sample.all.to_json }
    end
  end

  def new
    @sample = Sample.new
    @workflows  = Submission::Workflow.all
    @studies   = Study.all.sort_by {|p| p.name }
  end

  def create
    @sample = Sample.new(params[:sample])

    study_id = params[:study_id]
    if study_id
      study = Study.find(study_id)
      study.samples << @sample
    end

    respond_to do |format|
      if @sample.save
        flash[:notice] = "Sample successfully created"
        format.html { redirect_to sample_path(@sample) }
        format.xml  { render :xml => @sample, :status => :created, :location => @sample }
        format.json  { render :json => @sample, :status => :created, :location => @sample }
      else
        @workflows = Submission::Workflow.all
        flash[:error] = "Problems creating your new sample"
        format.html { render :action => :new }
        format.xml  { render :xml => @sample.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sample.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @sample  = Sample.find(params[:id], :include => :assets)
    @studies = Study.all(:conditions => ["state = ? OR state = ?", "pending", "active"], :order => :name)

    respond_to do |format|
      format.html
      format.xml { cache_xml_response(@sample) }
      format.json { render :json => @sample.to_json }
    end
  end

  def release
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      unless @sample.released?
        @sample.release
        flash[:notice] = "Sample '#{@sample.name}' publically released"
      else
        flash[:notice] = "Sample '#{@sample.name}' already publically released"
      end
      redirect_to sample_path(@sample)
    end
  end


  def edit
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      if @sample.released? && ! current_user.is_administrator?
        flash[:error] = "Cannot edit publically released sample"
        redirect_to sample_path(@sample)
        return
      end

      respond_to do |format|
        format.html
        format.xml  { render :xml => @samples.to_xml }
        format.json { render :json => @samples.to_json }
      end
    end
  end


  def update
    @sample = Sample.find(params[:id])
    redirect_if_not_owner_or_admin_otherwise do
      begin
        cleaned_params  = clean_params_from_check(params[:sample])
        @sample.update_attributes!(cleaned_params)
        flash[:notice] = "Sample details have been updated"
        redirect_to sample_path(@sample)
      rescue ActiveRecord::RecordInvalid => exception
        @workflows = Submission::Workflow.all
        flash[:error] = "Failed to update attributes for sample"
        render :action => "edit", :id => @sample.id
      end
    end
  end

  def destroy
    # TODO[5003153]: All of this code should be in Sample to ensure nobody does silly destructions ...
    @sample = Sample.find(params[:id])
    if @sample.has_submission?
      flash[:error] = "Failed: You can't delete '#{@sample.name}' because is linked to a submission."
      redirect_to samples_path
    else
      @sample.study_samples.each do |ps|
        ps.destroy
      end
      @assets = @sample.assets
      @assets.each do |asset|
        if !asset.asset_group_assets.empty?
          asset.asset_group_assets.each do |aga|
            aga.destroy
          end
        end
        asset.destroy
      end

      if @sample.destroy
        flash[:notice] = "Sample deleted"
      else
        flash[:notice] = "Failed to destroy sample"
      end
      redirect_to samples_path
    end
    # TODO[5003153]: ... to here, with appropriate exception raising and redirects here.
  end

  def history
    @sample = Sample.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def add_to_study
    sample = Sample.find(params[:id])
    study = Study.find(params[:study][:id])
    study.samples << sample
    redirect_to sample_path(sample)
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = exception.record.errors.full_messages
    redirect_to sample_path(sample)
  end

  def remove_from_study
    study = Study.find(params[:study_id])
    sample = Sample.find(params[:id])
    study.samples.delete(sample)
    study.save
    flash[:notice] = "Sample was removed from study #{study.name.humanize}"
    redirect_to sample_path(sample)
  end

  def show_accession
    @sample = Sample.find(params[:id])
    respond_to do |format|
      xml_text =@sample.accession_service.accession_sample_xml(@sample)
      format.xml  { render(:text => xml_text) }
    end
  end

  def accession
    @sample = Sample.find(params[:id])
    @sample.validate_ena_required_fields!
    @sample.accession_service.submit_sample_for_user(@sample, current_user)

    flash[:notice] = "Accession number generated: #{ @sample.sample_metadata.sample_ebi_accession_number }"
    redirect_to(sample_path(@sample))
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = 'Please fill in the required fields'
    redirect_to(edit_sample_path(@sample))
  rescue AccessionService::NumberNotRequired => exception
    flash[:warning] = 'An accession number is not required for this study'
    redirect_to(sample_path(@sample))
  rescue AccessionService::NumberNotGenerated => exception
    flash[:warning] = 'No accession number was generated'
    redirect_to(sample_path(@sample))
  rescue AccessionService::AccessionServiceError => exception
    flash[:error] = exception.message
    redirect_to(sample_path(@sample))
  end

   def taxon_lookup
     if params[:term]
       url= configatron.taxon_lookup_url+"/esearch.fcgi?db=taxonomy&term=#{params[:term].gsub(/\s/, '_')}"
     elsif params[:id]
       url = configatron.taxon_lookup_url+"/efetch.fcgi?db=taxonomy&mode=xml&id=#{params[:id]}"
     else return
     end

     c = Curl::Easy.new(URI.parse(url).to_s)
     if configatron.disable_web_proxy == true
       curl.proxy_url = ''
     elsif not configatron.proxy.blank?
       c.proxy_url= configatron.proxy
       c.headers["User-Agent"] = "Internet Explorer 5.0"
     end
     c.verbose = true
     c.perform
     body = c.body_str

     respond_to do |format|
       format.js {render :text =>body}
       format.xml {render :text =>body}
       #      format.html {render :nothing}
     end

   end

##### MOVE SECTION ######
  def move_spreadsheet
  end

  def process_spreadsheet(file)
    workbook = nil
    workbook = Spreadsheet.open(params[:file].path)

    if workbook
      worksheet = workbook.worksheet(0)
      # Assume there is always 1 header row
      num_rows = 0
      worksheet.each do
        num_rows = num_rows + 1
      end
      num_samples = num_rows - 1
      if num_samples > UPLOADED_SPREADSHEET_MAX_NUMBER_OF_MOVE_SAMPLES
        flash[:error] = "You can only load #{UPLOADED_SPREADSHEET_MAX_NUMBER_OF_MOVE_SAMPLES} samples at a time. Please split the file into smaller groups of samples."
        redirect_to move_spreadsheet_sample_path and return
      end

      used_definitions = []
      first_row = worksheet.row(0)
      #cycle for read parameter
      first_row.each do |cell|
        if cell != nil
          contents = cell #('latin1')
          used_definitions << contents
        end
      end

      @samples_to_move = {}

      1.upto(num_samples) do |row|
        sample_id = worksheet.cell(row,0).to_s.gsub(/\000/,'').gsub(/\.0/,'')
        unless sample_id == ''
          @samples_to_move[row] = {}
          used_definitions.each_with_index do |definition, index|
            @samples_to_move[row][definition] = worksheet.cell(row,index)
          end
          @samples_to_move[row]["xmsg"] = ""
        end
      end
    else
      flash[:error] = "Must select a file"
      redirect_to move_spreadsheet_sample_path and return
    end

    @samples_to_move
  end

  def move_upload
    if params["file"]
      begin
        @samples = process_spreadsheet(params[:file])
      rescue #BUG: much too narrow flash-message for such broad rescue
       if flash[:error].nil?
         flash[:error] = "Problems processing your file. Only Excel spreadsheets accepted. #{$!}"
       end
        redirect_to move_spreadsheet_samples_path and return
      end
    end

    error = false
    @samples.each do |progr, sample |
      params_for_move = {}.with_indifferent_access
      sample.sort.each do | key, value|
        params_for_move[key.to_sym] = value
      end

      params_for_move[:asset_group_id] = verify_asset_group(params_for_move[:asset_name])
      sample["asset_group_id"] = params_for_move[:asset_group_id]
      if params_for_move[:asset_group_id] == "0"
        params_for_move[:new_assets_name] = params_for_move[:asset_name]
      else
        params_for_move[:new_assets_name] = ""
      end

      valid_row = check_valid_submission_xls_row(params_for_move)
      if valid_row
        params_for_move[:submission_id] = "0"
        result = move_single_sample(params_for_move)
        if result
          sample["xmsg"] = "Sample has been moved"
        else
          sample["xmsg"] = "Error: Sample has NOT moved. Please contact helpdesk."
          error = true
        end
      else
        sample["xmsg"] = flash[:error]
        error = true
      end
    end

    if error
      flash[:error] = "Caution, errors were found. Lines with errors are not processed."
    end
  end

  def verify_asset_group(asset_group_name)
    asset = AssetGroup.find_by_name(asset_group_name)
    if asset.nil?
      asset_group_id = "0"
    else
      asset_group_id = asset.id
    end

    return asset_group_id
  end

  def filtered_move
    @studies = Study.all
    @studies.each do |study|
      study.name = study.name + " (" + study.id.to_s + ")"
    end
    @sample = Sample.find(params[:id])
    @studies_from = @sample.studies
    @assets = []
    @submissions = []
  end

  def move_single_sample(params)
    @sample         = Sample.find(params[:id])
    @study_from     = Study.find(params[:study_id_from])
    @study_to       = Study.find(params[:study_id_to])
    @asset_group    = AssetGroup.find_by_id(params[:asset_group_id])
    if @asset_group.nil?
      @asset_group    = AssetGroup.find_or_create_asset_group(params[:new_assets_name], @study_to)
    end

    return @study_to.take_sample(@sample, @study_from, current_user, @asset_group)
  end

  def move
    @sample = Sample.find(params[:id])
    unless check_valid_values(params)
      redirect_to :action => :filtered_move, :id => params[:id]
      return
    end

    result = move_single_sample(params)
    if result
      flash[:notice] = "Sample has been moved"
      redirect_to sample_path(@sample)
    else
      #flash[:error] = @sample.error
      flash[:error] = @sample.errors.full_messages.join("<br />")
      redirect_to :action => "filtered_move", :id => @sample.id
    end
  end

  def select_asset_name_for_move
    @sample = Sample.find(params[:sample_id])
    @asset_groups = Study.find_by_id(params[:study_id_to]).try(:asset_groups) || []
    render :layout => false
  end

  def select_submission_for_move
    sample = Sample.find(params[:sample_id])
    @submissions = Sample.submissions_by_assets(params[:study_id_to], params[:asset_group_id])
    render :layout => false
  end

  def reset_values_for_move
    render :layout => false
  end

  def show_submissions
    @list_of_submissions = []
    if params[:study_id_from] != "0"
      sample = Sample.find( params[:sample_id] )
      @list_of_submissions = sample.submissions.for_studies(params[:study_id_from])
    end
    render :layout => false
  end

private

  def check_valid_values(params = nil)
    if check_valid_selection(params) && check_valid_submission_type(params)
      return true
    end
    return false
  end

  def check_valid_selection(params = nil)
    if (params[:study_id_to] == "0") || (params[:study_id_from] == "0")
      flash[:error] = "You have to select 'Study From' and 'Study To'"
      return false
    else
      study_from = Study.find(params[:study_id_from])
      study_to = Study.find(params[:study_id_to])
      if study_to.name.eql?(study_from.name)
        flash[:error] = "You can't select the same Study."
        return false
      elsif params[:asset_group_id] == "0" && params[:new_assets_name].empty?
          flash[:error] = "You must indicate an 'Asset Group'."
          return false
      elsif !(params[:asset_group_id] == "0") && !(params[:new_assets_name].empty?)
          flash[:error] = "You can select only an Asset Group!"
          return false
      elsif AssetGroup.find_by_name(params[:new_assets_name])
          flash[:error] = "The name of Asset Group exists!"
          return false
      end
    end
    return true
  end

  def check_valid_submission_xls_row(params_for_move)
    valid = true
    if !check_valid_values(params_for_move)
      #sample["xmsg"] = flash[:error]
      valid = false
    else
      @sample = Sample.find_by_id(params_for_move[:id]);
      if @sample.nil?
        flash[:error] = "The sample don't exist."
        valid = false
      else
        study = @sample.studies.find_by_id(params_for_move[:study_id_from])
        if study.nil?
          flash[:error] = "The sample is not belonging to study_from"
          valid = false
        else
          assetgroup = AssetGroup.find_by_name(params_for_move[:asset_name])
          if !assetgroup.nil?
            if assetgroup.study_id != params_for_move[:study_id_to].to_i
              flash[:error] = "The Asset Group is not belong to study_to"
              valid = false
            end
          end
        end
      end
    end
    return valid
  end

  def check_valid_submission_type(params = nil)
    return true # we dont' care about submissin anymore
    submission_selected = Sample.submissions_by_assets(params[:study_id_to], params[:asset_group_id])
    if ! (submission_selected.empty?) && (params[:submission_id] == "0") && (params[:new_assets_name].empty?)
      flash[:error] = "You must select a Submission because you select an Asset with Submissions."
      return false
    end
    return true
  end

  def redirect_if_not_owner_or_admin_otherwise(&block)
    return yield if current_user.owner?(@sample) or current_user.is_administrator? or current_user.is_manager?

    # TODO: @sample.user is no longer a method.  something needed there
    #      flash[:error] = "Sample details can only be altered by the owner (#{@sample.user.login}) or an administrator or manager"
    flash[:error] = "Sample details can only be altered by the owner or an administrator or manager"
    redirect_to sample_path(@sample)
  end
end
