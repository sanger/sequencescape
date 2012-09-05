class StudyReportsController < ApplicationController
  before_filter :login_required

  def index
    @study_reports = StudyReport.without_files.paginate(:page => params[:page], :order => "id desc")
    @studies = Study.all(:order => "name ASC")
  end

  def new
    params[:study_report] = {:study => params[:study]}
    create
  end

  def create
    study = Study.find_by_id(params[:study_report][:study])
    study_report = StudyReport.create!(:study => study, :user => @current_user)

    study_report.perform

    respond_to do |format|
      if study_report
        flash[:notice] = "Report being generated"
        format.html { redirect_to( study_reports_path ) }
        format.xml  { render :xml  => study_report, :status => :created, :location => study_report }
        format.json { render :json => study_report, :status => :created, :location => study_report }
      else
        flash[:error] = "Error: report not being generated"
        format.html { redirect_to( study_reports_path ) }
        format.xml  { render :xml  => flash[:error], :status => :unprocessable_entity }
        format.json { render :json => flash[:error], :status => :unprocessable_entity }
      end
    end
  end

  def show
    study_report = StudyReport.find(params[:id])
    send_data( study_report.report.data, :type => "text/plain",
    :filename=>"#{study_report.study.dehumanise_abbreviated_name}_progress_report.csv",
    :disposition => 'attachment')
  end


end

