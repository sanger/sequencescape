class Studies::WorkflowsController < ApplicationController

  include TableauTrustedInterface

  before_filter :discover_study, :discover_workflow

  before_filter :setup_tabs, :only => [ :show_summary, :show, :show_oldss, :show_tableau ]

  def setup_tabs

    @total_requests = compute_total_request(@study)
    @cache          = { :total => @total_requests }

    @request_types  = @workflow.request_types.all(:order => "`order` ASC").reject { |r| @total_requests[r].zero? }

    @summaries = basic_tabs + @request_types.map(&:name)
  end
  private :setup_tabs
  
  def basic_tabs
    ["Summary", "Sample progress", "Assets progress"]
  end
  private :basic_tabs

  def is_tableau_report?
    (@is_tableau_report == 1)
  end

  def log_info_reports
    "url: #{request.url}, referer: #{request.referer}, ua: #{request.user_agent}"
  end

  def show
    show_tableau
  end 

  def show_tableau
    flash.now[:alert] = "This is the <b>NEW</b> version of the reports. You can still access the previous version by <a href='#{study_workflow_path(@study, @workflow)}/reports/oldss'>clicking here</a>"
    Rails.logger.warn("StudyRequestReport NEW - #{log_info_reports}")
    @is_tableau_report = 1
    #@ticket = get_tableau_ticket(@view_name)

    tabserver = configatron.reporting_server
    tabuser   = 'workgroupuser'
    tabpath   = 'views/Book1/Sheet1'
    tabparams = ':embed=yes&:toolbar=no'
    @ticket    = tableau_get_trusted_ticket(tabserver, tabuser, request.remote_ip)
 
    if @ticket != "-1"
      @iframe_url = "http://#{tabserver}/trusted/#{ticket}/#{tabpath}?#{tabparams}"
    end

    _show
  end

  def show_oldss
    flash.now[:alert] = "This is the <b>OLD</b> version of the reports. You can access the new version by <a href='#{study_workflow_path(@study, @workflow)}/reports/tableau'>clicking here</a>"
    Rails.logger.warn("StudyRequestReport DEPRECATED - #{log_info_reports}")
    @is_tableau_report = 0
    _show
  end

  def _show
    Study.benchmark "BENCH Study:WorkflowController:show", Logger::DEBUG, false do
      unless @current_user.nil?
        @current_user.workflow = @workflow
        @current_user.save!
      end
      @workflows = Submission::Workflow.find(:all, :order => ["name DESC"])
      @default_tab_label = "Sample progress"
      @summary = params[:summary].to_i
      @summary = basic_tabs.index(@default_tab_label) if params[:summary].nil?
      @submissions = @study.submissions_for_workflow(@workflow)
      # We need to propagate the extra_parameters - as page - to the summary partial
      @extra_params = params.dup
      [:summary, :study_id, :id, :action, :controller].each do |key|
        @extra_params.delete key
      end
      @is_tableau_report = is_tableau_report?
      respond_to do |format|
        format.html { render :action => :show}
        format.xml
        format.json { render :action => :show, :json => Study.all.to_json }
      end
    end
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
      @summary = params[:summary].to_i
      @summary = basic_tabs.index(@default_tab_label) if params[:summary].nil?

      case @summaries[@summary]
      when "Sample progress"
        @page_elements  = @study.samples.paginate(page_params)
        sample_ids      = @page_elements.map(&:id)
        render :partial => "sample_progress"
      when "Assets progress"
        @page_elements= @study.assets_through_aliquots.paginate(page_params)
        asset_ids = @page_elements.map { |e| e.id }

        @cache.merge!(:passed => @passed_asset_request, :failed => @failed_asset_request)
        render :partial => "asset_progress"
      when "Summary"
        @page_elements= @study.assets_through_requests.for_summary.paginate(page_params)
        asset_ids = @page_elements.map { |e| e.id }
        render :partial => "summary"
      else
        @request_type = @request_types[@summary - basic_tabs.size]
        @assets_to_detail = @study.requests.request_type(@request_type).with_asset.all(:include =>:asset).map(&:asset).uniq

        unless @assets_to_detail.empty?
          render :partial => "summary_for_request_type"
        else
          render :text => "No requests of this type can be found"
        end
      end
    else
      page_params[:summary]= params[:summary]
      redirect_to ss_report_study_workflow_path(@study, @workflow, page_params)
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
    report =  @study.total_requests_report
    @workflow.request_types.each do |rt|
      total_requests[rt] = report[rt.id]||0
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

  private
  def discover_study
    @study  = Study.find(params[:study_id])
    flash[:warning] = "#{flash[:warning]} #{@study.warnings}" if @study.warnings.present?
  end

  def discover_workflow
    @workflow = Submission::Workflow.find(params[:id])
  end

  def ss_report_study_workflow_path(study, workflow, params)
    "#{study_workflow_path(study, workflow)}/reports/oldss?#{Rack::Utils.build_query(params)}"
  end
end

