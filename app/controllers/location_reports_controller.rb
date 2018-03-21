# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class LocationReportsController < ApplicationController
  before_action :login_required

  def index
    setup_form_selects
    # @location_report        = LocationReport.new(user: @current_user)

    @form_object = LocationReport::FormObject.new(user: @current_user)

    respond_to do |format|
      format.html
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

  def create
    # @location_report        = LocationReport.new(location_report_parameters)
    # @location_report.user   = @current_user
    @form_object = LocationReport::FormObject.new(location_report_for_object_params)
    @form_object.user = @current_user

    respond_to do |format|
      if @form_object.save
        flash[:notice] = I18n.t('location_reports.success')
        format.html { redirect_to location_reports_path }
      else
        error_messages          = @location_report.errors.full_messages.join('; ')
        flash.now[:error]       = "Failed to create report: #{error_messages}"
        setup_form_selects
        # @location_report.errors.clear
        @form_object.errors.clear
        format.html { render action: 'index' }
      end
    end
  end

  private

  def setup_form_selects
    @faculty_sponsors       = FacultySponsor.alphabetical.pluck(:name, :id)
    @studies                = Study.alphabetical.pluck(:name, :id)
    @plate_purposes         = PlatePurpose.alphabetical.pluck(:name, :id)
    @location_reports       = LocationReport.order(id: :desc).page(params[:page])
  end

  # def location_report_parameters
  #   params.require(:location_report).permit(:report_type, :name, :barcodes_text, :study_id, :start_date, :end_date, plate_purpose_ids: [])
  # end

  def location_report_for_object_params
    params.require(:location_report).permit(:report_type, :name, :barcodes_text, :study_id, :start_date, :end_date, plate_purpose_ids: [])
  end
end
