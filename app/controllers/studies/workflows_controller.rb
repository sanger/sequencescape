class Studies::WorkflowsController < ApplicationController
  before_filter :discover_study, :discover_workflow

  def show
    Study.benchmark "BENCH Study:WorkflowController:show", Logger::DEBUG, false do
    unless @current_user.nil?
      @current_user.workflow = @workflow
      @current_user.save!
    end
    @workflows = Submission::Workflow.find(:all, :order => ["name DESC"])

    @default_tab_label = "Sample progress"
    @basic_tabs = ["Summary", @default_tab_label, "Assets progress", "Project quotas"]
    @summaries = @basic_tabs + @workflow.request_types.map { |rt| rt.name.capitalize }

    @summary = params[:summary].to_i
    if params[:summary].nil?
      @summary = @basic_tabs.index(@default_tab_label)
    end

    @submissions = @study.submissions_for_workflow(@workflow)

    # We need to propagate the extra_parameters - as page - to the summary partial
    @extra_params = params.dup
    [:summary, :study_id, :id, :action, :controller].each do |key|
      @extra_params.delete key
    end

    respond_to do |format|
      format.html
      format.xml
      format.json { render :json => Study.all.to_json }
    end
    end # of benchhmark
  end

  def show_summary
    # Dirty : in ajax request, paramter are escaped twice ...
    params.each do |key, value|
      new_key = key.sub(/^amp;/, "")
      next if new_key == key
      params[new_key]=value
    end
    page_params= { :page => params[:page] || 1, :per_page => params[:per_page] || 50 }

    if request.xhr?

      @default_tab_label = "Assets progress"
      @basic_tabs = ["Summary", "Sample progress", @default_tab_label, "Project quotas"]
      @summaries = @basic_tabs + @workflow.request_types.map { |rt| rt.name.capitalize }

      @summary = params[:summary].to_i
      if params[:summary].nil?
        @summary = @basic_tabs.index(@default_tab_label)
      end


      case @summaries[@summary]
      when "Sample progress"
        @page_elements= @study.samples.paginate(page_params)
        sample_ids = @page_elements.map { |e| e.id }
        @request_types = @workflow.request_types.all(:order => "`order` ASC")
        @total_requests = compute_total_request(@study)
        @total_sample_request = group_sample_request(@study, sample_ids)
        @passed_sample_request = group_sample_passed_request(@study, sample_ids)
        @failed_sample_request = group_sample_failed_request(@study, sample_ids)


        @cache = { :total => @total_requests, :passed => @passed_sample_request, :failed => @failed_sample_request }
        render :partial => "sample_progress"
      when "Assets progress"
        @page_elements= @study.assets.paginate(page_params)
        asset_ids = @page_elements.map { |e| e.id }
        Study.benchmark " compute_total_request" do
          @total_requests = compute_total_request(@study)
        end
        Study.benchmark " group_asset_request" do
          @total_asset_request = group_asset_request(@study, asset_ids)
        end
        Study.benchmark " group_asset_passed_request" do
          @passed_asset_request = group_asset_passed_request(@study, asset_ids)
        end
        Study.benchmark " group_asset_failed_request" do
          @failed_asset_request = group_asset_failed_request(@study, asset_ids)
        end


        @cache = { :total => @total_requests, :passed => @passed_asset_request, :failed => @failed_asset_request }
        render :partial => "asset_progress"
      when "Summary"
        render :partial => "summary"
      when "Project quotas"
        @projects = @study.projects.paginate(page_params)
        render :partial => "shared/project_listing_quotas"
      else
        @request_types = @workflow.request_types
        @request_type = @request_types[@summary - @basic_tabs.size]

        @assets_to_filter = @study.assets
        @assets_to_detail = @assets_to_filter.select do |asset|
          ! asset.requests.detect{ |r| r.request_type == @request_type }.nil?
        end

        unless @assets_to_detail.empty?
          render :partial => "summary_for_request_type"
        else
          render :text => "No requests of this type can be found"
        end
      end
    else
      page_params[:summary]= params[:summary]
      redirect_to study_workflow_path(@study, @workflow, page_params)
    end
  end

  def summary
    s = UiHelper::Summary.new
    @summary = s.load(@study, @workflow).paginate :page => params[:page], :order => 'created_at DESC'
    # @summary.load(@study, @workflow)
    respond_to do |format|
      format.html
    end
  end

  def compute_total_request(study)
    total_requests = { }
    @workflow.request_types.each do |rt|
      total_requests[rt] = @study.total_requests(rt)
    end
    total_requests
  end

  def group_count(enumerable)
    map = Hash.new { |hash, key| hash[key]= Hash.new 0 } # defining default value for nested hash
    enumerable.each do |e|
      groups = yield(e)
      groups.each do  |g_id, count|
        map[g_id.to_i][e]= count
      end
    end
    map
  end
   def old_group_sample_request(study)
    samples_map = Hash.new { |hash, key| hash[key]= Hash.new 0 } # defining default value for nested hash
    @workflow.request_types.each do |rt|
      groups = study.requests.request_type(rt).count(:group => :sample_id)
      groups.each do  |sample_id, count|
        samples_map[sample_id.to_i][rt]= count
      end
    end
    samples_map
  end


 def old_group_asset_request(study)
    assets_map = Hash.new { |hash, key| hash[key]= Hash.new 0 } # defining default value for nested hash
    @workflow.request_types.each do |rt|
      groups = study.requests.request_type(rt).count(:group => :asset_id)
      groups.each do  |asset_id, count|
        assets_map[asset_id.to_i][rt]= count
      end
    end
    assets_map
  end

   def group_sample_request(study, sample_ids=nil)
     return [ ] if sample_ids && sample_ids.empty? # /|\ nil means all sample
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).join_asset.count(:group => :sample_id, :having => (sample_ids && "sample_id in (#{sample_ids.join(', ')})"))
     end
   end
   def group_sample_passed_request(study, sample_ids=nil)
     return [ ] if sample_ids && sample_ids.empty? # /|\ nis means all sample
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).passed.join_asset.count(:group => :sample_id, :having => (sample_ids && "sample_id in (#{sample_ids.join(', ')})"))
     end
   end
   def group_sample_failed_request(study, sample_ids=nil)
     return [ ] if sample_ids && sample_ids.empty? # /|\ nis means all sample
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).failed.join_asset.count(:group => :sample_id, :having => (sample_ids && "sample_id in (#{sample_ids.join(', ')})"))
     end
   end
   def group_asset_request(study, asset_ids = nil)
     return [ ] if asset_ids && asset_ids.empty? # /|\ nis means all asset
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).count(:group => :asset_id, :having => (asset_ids &&"asset_id in (#{asset_ids.join(', ')})") )
     end
   end
   def group_asset_passed_request(study, asset_ids = nil)
     return [ ] if asset_ids && asset_ids.empty? # /|\ nis means all asset
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).passed.count(:group => :asset_id, :having => (asset_ids &&"asset_id in (#{asset_ids.join(', ')})") )
     end
   end
   def group_asset_failed_request(study, asset_ids = nil)
     return [ ] if asset_ids && asset_ids.empty? # /|\ nis means all asset
     group_count(@workflow.request_types) do |rt|
      groups = study.requests.request_type(rt).failed.count(:group => :asset_id, :having => (asset_ids &&"asset_id in (#{asset_ids.join(', ')})") )
     end
   end

  private
  def discover_study
    @study  = Study.find(params[:study_id])
  end

  def discover_workflow
    @workflow = Submission::Workflow.find(params[:id])
  end
end
