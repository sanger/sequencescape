
class Studies::InformationController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_study, :standard_request_types

  before_action :setup_tabs, only: %i[show show_summary]

  def setup_tabs
    @total_requests = compute_total_request
    @cache          = { total: @total_requests }

    # Request types are already loaded, so we sort in ruby
    @request_types  = standard_request_types.order(:order).reject { |r| @total_requests[r].zero? }

    @basic_tabs = ['Summary', 'Sample progress', 'Assets progress']
    @summaries = @basic_tabs + @request_types.map(&:name)
  end
  private :setup_tabs

  def show
    @default_tab_label = 'Sample progress'
    @summary = params[:summary].to_i
    @summary = @basic_tabs.index(@default_tab_label) if params[:summary].nil?

    @submissions = @study.submissions
    @awaiting_submissions = @study.submissions.where.not(state: 'ready')

    # We need to propagate the extra_parameters - as page - to the summary partial
    @extra_params = params.dup
    %i[summary study_id id action controller].each do |key|
      @extra_params.delete key
    end

    respond_to do |format|
      format.html
      format.xml
      format.json { render json: Study.all.to_json }
    end
  end

  def show_summary
    # Dirty : in ajax request, paramter are escaped twice ...
    params.each do |key, value|
      new_key = key.sub(/^amp;/, '')
      next if new_key == key
      params[new_key] = value
    end
    page_params = { page: params[:page] || 1, per_page: params[:per_page] || 50 }

    if request.xhr?
      @default_tab_label = 'Assets progress'
      @summary = params[:summary].to_i
      @summary = @basic_tabs.index(@default_tab_label) if params[:summary].nil?

      case @summaries[@summary]
      when 'Sample progress'
        @page_elements = @study.samples.paginate(page_params)
        render partial: 'sample_progress'
      when 'Assets progress'
        @asset_type = Receptacle.descendants.detect { |cls| cls.name == params[:asset_type] } || Receptacle
        @asset_type_name = params.fetch(:asset_type, 'All Assets').underscore.humanize
        @page_elements = @study.assets_through_aliquots.of_type(@asset_type).paginate(page_params)
        @cache[:passed] = @passed_asset_request
        @cache[:failed] = @failed_asset_request
        render partial: 'asset_progress'
      when 'Summary'
        @page_elements = @study.assets_through_requests.for_summary.paginate(page_params)
        render partial: 'summary'
      else
        @request_type = @request_types[@summary - @basic_tabs.size]
        # The include here doesn't load ALL the requests, only those matching the given request type. Ideally we'd just grab the counts,
        # but unfortunately we need to have at least the request id available for linking to in cases where we have
        # only one request in a particular state.
        @assets_to_detail = Receptacle.for_study_and_request_type(@study, @request_type).includes(:requests).paginate(page_params)
        # Example group by count which would allow us to do returned_hash[[asset_id,state]] to get the count for a particular asset/state
        # Unfortunately this doesn't let us grab the request id. We could use some custom SQL to achieve this, but we'll see how
        # effective the above is before trying that.
        # Receptacle.for_study_and_request_type(@study,@request_type).where(id:@assets_to_detail.map(&:id)).group('assets.id','requests.state').count
        if @assets_to_detail.empty?
          render plain: 'No requests of this type can be found'
        else
          render partial: 'summary_for_request_type'
        end
      end
    else
      page_params[:summary] = params[:summary]
      redirect_to study_information_path(@study, page_params)
    end
  end

  def summary
    s = UiHelper::Summary.new
    @summary = s.load(@study).paginate page: params[:page], per_page: 30
    respond_to do |format|
      format.html
    end
  end

  def compute_total_request
    report = @study.total_requests_report(standard_request_types)
    standard_request_types.each_with_object({}) do |rt, total_requests|
      total_requests[rt] = report[rt.id] || 0
    end
  end

  def group_count(enumerable)
    map = Hash.new { |hash, key| hash[key] = Hash.new 0 } # defining default value for nested hash
    enumerable.each do |e|
      groups = yield(e)
      groups.each do |g_id, count|
        map[g_id.to_i][e] = count
      end
    end
    map
  end

  private

  def standard_request_types
    @standard_request_types ||= RequestType.standard
  end

  def discover_study
    @study = Study.find(params[:study_id])
    flash.now[:warning] = @study.warnings if @study.warnings.present?
  end
end
