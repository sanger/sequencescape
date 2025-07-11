# frozen_string_literal: true
class StudyReportsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :login_required

  def index
    @study_reports = StudyReport.order(id: :desc).page(params[:page])
    @studies = Study.alphabetical
  end

  def show
    study_report = StudyReport.find(params[:id])
    send_data(
      study_report.report.read,
      type: 'text/plain',
      filename: "#{study_report.study.dehumanise_abbreviated_name}_progress_report.csv",
      disposition: 'attachment'
    )
  end

  def new
    params[:study_report] = { study: params[:study] }
    create
  end

  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    study = Study.find_by(id: params[:study_report][:study])
    study_report = StudyReport.create!(study: study, user: @current_user)

    study_report.schedule_report

    respond_to do |format|
      if study_report
        flash[:notice] = 'Report being generated'
        format.html { redirect_to(study_reports_path) }
        format.xml { render xml: study_report, status: :created, location: study_report }
        format.json { render json: study_report, status: :created, location: study_report }
      else
        flash[:error] = 'Error: report not being generated'
        format.html { redirect_to(study_reports_path) }
        format.xml { render xml: flash[:error], status: :unprocessable_entity }
        format.json { render json: flash[:error], status: :unprocessable_entity }
      end
    end
  end
end
