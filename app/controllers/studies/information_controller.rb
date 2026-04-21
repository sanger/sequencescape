# frozen_string_literal: true

# Responsible for displaying overcomplicated reporting pages
class Studies::InformationController < ApplicationController
  BASIC_TABS = [
    %w[summary Summary],
    ['sample-progress', 'Sample progress'],
    ['assets-progress', 'Assets progress'],
    ['accession-statuses', 'Accession statuses']
  ].freeze
  PAGED_TABLE_LAYOUT = 'studies/information/layouts/paged_table'

  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_study

  def show
    @page_name = @study.name

    @submissions = @study.submissions
    @awaiting_submissions = @study.submissions.where.not(state: 'ready')

    # We need to propagate the extra_parameters - as page - to the summary partial
    @extra_params = params.except(%i[summary study_id id action controller])

    respond_to do |format|
      format.html
      format.xml
      format.json { render json: Study.all.to_json }
    end
  end

  def show_items
    @summary = params[:summary] || 'sample-progress'
    @request_types = study_request_types
    @summaries = BASIC_TABS + @request_types.pluck(:key, :name)
    @extra_params = params.except(%i[summary study_id id action controller])

    render partial: 'items', locals: { summary: @summary }
  end

  def show_study_summary
    @request_types = study_request_types

    render partial: 'study_summary'
  end

  # Dynamically load the contents of this endpoint via ajax_handling.js to populate the summary tab tables.
  def show_summary
    page_params = { page: params[:page] || 1, per_page: params[:per_page] || 50 }

    @summary = params[:summary] || 'assets-progress'

    case @summary
    when 'summary'
      render_summary(page_params)
    when 'sample-progress'
      render_sample_progress(page_params)
    when 'assets-progress'
      render_assets_progress(page_params)
    when 'accession-statuses'
      render_accession_statuses(page_params)
    else
      render_request_type_summary(page_params)
    end
  end

  def summary
    s = UiHelper::Summary.new
    @summary = s.load(@study).paginate page: params[:page], per_page: 30
    respond_to { |format| format.html }
  end

  private

  def discover_study
    @study = Study.find(params[:study_id])
    flash.now[:warning] = @study.warnings if @study.warnings.present?
  end

  def render_summary(page_params)
    @page_elements = @study.assets_through_requests.for_summary.includes('barcodes').paginate(page_params)

    render partial: 'summary', layout: PAGED_TABLE_LAYOUT
  end

  def render_sample_progress(page_params)
    @page_elements = @study.samples.paginate(page_params)
    @request_types = study_request_types

    render partial: 'sample_progress', layout: PAGED_TABLE_LAYOUT
  end

  def render_assets_progress(page_params)
    @request_types = study_request_types
    @labware_type = Labware.descendants.detect { |cls| cls.name == params[:labware_type] } || Labware
    @labware_type_name = params.fetch(:labware_type, 'All Assets').underscore.humanize
    @page_elements = @study.assets_through_aliquots.on_a(@labware_type).paginate(page_params)

    render partial: 'asset_progress', layout: PAGED_TABLE_LAYOUT
  end

  def render_accession_statuses(page_params)
    @page_elements = @study.samples
      .includes(:sample_metadata, :accession_sample_statuses, studies: :study_metadata)
      .paginate(page_params)

    render partial: 'accession_statuses', layout: PAGED_TABLE_LAYOUT
  end

  def render_request_type_summary(page_params)
    # A request_type key
    @request_type = RequestType.find_by!(key: params[:summary])

    # The include here doesn't load ALL the requests, only those matching the given request type. Ideally we'd just
    # grab the counts, but unfortunately we need to have at least the request id available for linking to in cases
    # where we have only one request in a particular state.
    @page_elements =
      Receptacle.for_study_and_request_type(@study, @request_type).includes(:requests).paginate(page_params)

    # Example group by count which would allow us to do returned_hash[[asset_id,state]] to get the count for a
    # particular asset/state
    # Unfortunately this doesn't let us grab the request id. We could use some custom SQL to achieve this, but
    # we'll see how effective the above is before trying that.

    # Receptacle.for_study_and_request_type(@study,@request_type)
    #  .where(id:@page_elements.map(&:id)).group('assets.id','requests.state').count

    if @page_elements.empty?
      render partial: 'no_requests_found'
    else
      render partial: 'summary_for_request_type', layout: PAGED_TABLE_LAYOUT
    end
  end

  def study_request_types
    @study_request_types ||= @study.request_types.standard.order(:order, :id)
  end
end
