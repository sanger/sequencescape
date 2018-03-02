# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class LocationReportsController < ApplicationController
  before_action :login_required

  def index
    @studies                = Study.alphabetical.pluck(:name, :id)
    @plate_purposes         = PlatePurpose.alphabetical.pluck(:name, :id)
    @location_reports       = LocationReport.order(id: :desc).page(params[:page])
    @location_report        = LocationReport.new(user: @current_user)
  end

  def create
    @location_report        = LocationReport.new(location_report_parameters)
    @location_report.user   = @current_user

    if @location_report.save
      flash[:notice] = I18n.t('location_reports.success')
      redirect_to location_reports_path
    else
      error_messages          = @location_report.errors.full_messages.join('; ')
      flash.now[:error]       = "Failed to create report: #{error_messages}"
      @studies                = Study.alphabetical.pluck(:name, :id)
      @plate_purposes         = PlatePurpose.alphabetical.pluck(:name, :id)
      @location_reports       = LocationReport.order(id: :desc).page(params[:page])
      @location_report.errors.clear
      render 'index'
    end
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

  private

  def location_report_parameters
    params.require(:location_report).permit(:report_type, :barcodes_text, :study_id, :start_date, :end_date, plate_purpose_ids: [])
  end
end
