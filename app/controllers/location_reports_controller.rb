# frozen_string_literal: true

##
# This class handles creating and viewing Location Reports, which match up plates to their
# recorded physical location, and to their Studies and Faculty Sponser (can be multiple per
# plate). These reports are used by the Sample Management team to manage storage space in
# freezers and to locate old plates for return to their owners or disposal.
class LocationReportsController < ApplicationController
  before_action :login_required

  def index
    @location_reports = LocationReport.order(id: :desc).page(params[:page])
    @location_report_form = LocationReport::LocationReportForm.new
    @location_report_form.user = @current_user

    respond_to { |format| format.html }
  end

  def show
    @location_report = LocationReport.find(params[:id])

    send_data(
      @location_report.report.read,
      type: 'text/plain',
      filename: "location_report_#{@location_report.name}.csv",
      disposition: 'attachment'
    )
  end

  def create # rubocop:todo Metrics/AbcSize
    @location_report_form = LocationReport::LocationReportForm.new(location_report_params)
    @location_report_form.user = @current_user

    respond_to do |format|
      if @location_report_form.save
        flash[:notice] = I18n.t('location_reports.success')
        format.html { redirect_to location_reports_path }
      else
        error_messages = @location_report_form.errors.full_messages.join('; ')
        flash.now[:error] = "Failed to create report: #{error_messages}"
        @location_reports = LocationReport.order(id: :desc).page(params[:page])
        format.html { render action: 'index' }
      end
    end
  end

  #######

  private

  #######

  def location_report_params # rubocop:todo Metrics/MethodLength
    params
      .require(:location_report)
      .permit(
        :report_type,
        :name,
        :location_barcode,
        :barcodes,
        :barcodes_text,
        :study_id,
        :start_date,
        :end_date,
        :barcodes,
        :barcodes_text,
        faculty_sponsor_ids: [],
        plate_purpose_ids: []
      )
  end
end
