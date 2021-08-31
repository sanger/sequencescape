# frozen_string_literal: true

# Responsible for displaying overcomplicated reporting pages
class Studies::InformationController < ApplicationController
  BASIC_TABS = [
    %w[summary Summary],
    ['sample-progress', 'Sample progress'],
    ['assets-progress', 'Assets progress']
  ].freeze

  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :discover_study

  def show # rubocop:todo Metrics/AbcSize
    @summary = params[:summary] || 'sample-progress'
    @request_types = RequestType.where(id: @study.requests.distinct.pluck(:request_type_id)).standard.order(:order, :id)
    @summaries = BASIC_TABS + @request_types.pluck(:key, :name)

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

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def show_summary # rubocop:todo Metrics/CyclomaticComplexity
    page_params = { page: params[:page] || 1, per_page: params[:per_page] || 50 }

    if request.xhr?
      @summary = params[:summary] || 'assets-progress'

      case @summary
      when 'sample-progress'
        @page_elements = @study.samples.paginate(page_params)
        @request_types =
          RequestType.where(id: @study.requests.distinct.pluck(:request_type_id)).standard.order(:order, :id)
        render partial: 'sample_progress'
      when 'assets-progress'
        @request_types =
          RequestType.where(id: @study.requests.distinct.pluck(:request_type_id)).standard.order(:order, :id)
        @labware_type = Labware.descendants.detect { |cls| cls.name == params[:labware_type] } || Labware
        @labware_type_name = params.fetch(:labware_type, 'All Assets').underscore.humanize
        @page_elements = @study.assets_through_aliquots.on_a(@labware_type).paginate(page_params)
        render partial: 'asset_progress'
      when 'summary'
        @page_elements = @study.assets_through_requests.for_summary.paginate(page_params)
        render partial: 'summary'
      else
        # A request_type key
        @request_type = RequestType.find_by!(key: params[:summary])

        # The include here doesn't load ALL the requests, only those matching the given request type. Ideally we'd just
        # grab the counts, but unfortunately we need to have at least the request id available for linking to in cases
        # where we have only one request in a particular state.
        @assets_to_detail =
          Receptacle.for_study_and_request_type(@study, @request_type).includes(:requests).paginate(page_params)

        # Example group by count which would allow us to do returned_hash[[asset_id,state]] to get the count for a
        # particular asset/state
        # Unfortunately this doesn't let us grab the request id. We could use some custom SQL to achieve this, but
        # we'll see how effective the above is before trying that.

        # Receptacle.for_study_and_request_type(@study,@request_type)
        #  .where(id:@assets_to_detail.map(&:id)).group('assets.id','requests.state').count

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

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

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
end
