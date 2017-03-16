# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class QcReportsController < ApplicationController
  before_action :login_required
  before_action :check_required, only: :create

  def index
    # Build a conditions hash of acceptable parameters, ignoring those that are blank

    @qc_reports = QcReport.for_report_page(conditions).page(params[:page]).includes(:study, :product)
    @qc_report = QcReport.new(exclude_existing: true, study_id: params[:study_id])
    @studies = Study.alphabetical.pluck(:name, :id)
    @states = QcReport.available_states.map { |s| [s.humanize, s] }

    @all_products = Product.alphabetical.all.map { |product| [product.display_name, product.id] }
    @active_products = Product.with_stock_report.active.alphabetical.all.map { |product| [product.display_name, product.id] }
  end

  def create
    study = Study.find_by(id: params[:qc_report][:study_id])
    exclude_existing = params[:qc_report][:exclude_existing] == '1'

    qc_report = QcReport.new(study: study, product_criteria: @product.stock_criteria, exclude_existing: exclude_existing)

    if qc_report.save
      flash[:notice] = 'Your report has been requested and will be presented on this page when complete.'
      redirect_to qc_report
    else # We failed to save
      error_messages = qc_report.errors.full_messages.join('; ')
      flash[:error] = "Failed to create report: #{error_messages}"
      redirect_to :back
    end
  end

  # On form submit of a qc_file. Strictly speaking this should be an update action
  # on the qc_report itself. However we don't want to force the user to extract
  # the report identifier from the file.
  def qc_file
    qc_file = params[:qc_report_file]
    overide_qc = params[:overide_qc_decision] == '1'
    file = QcReport::File.new(qc_file, overide_qc, qc_file.original_filename, qc_file.content_type)
    if file.process
      redirect_to file.qc_report
    else
      flash[:error] = "Failed to read report: #{file.errors.join('; ')}"
      redirect_to :back
    end
  end

  def show
    qc_report = QcReport.find_by(report_identifier: params[:id])
    queue_count = qc_report.queued? ? Delayed::Job.count : 0
    @report_presenter = Presenters::QcReportPresenter.new(qc_report, queue_count)

    respond_to do |format|
      format.html

      format.csv do
        file = nil
        begin
          file = Tempfile.new(@report_presenter.filename)
          @report_presenter.to_csv(file)
          file.flush
        ensure
          file.close unless file.nil?
        end
        send_file file.path, content_type: 'text/csv', filename: @report_presenter.filename
      end if qc_report.available?
    end
  end

  private

  def check_required
    return fail('No report options were provided') unless params[:qc_report].present?
    return fail('You must select a product') if params[:qc_report][:product_id].nil?
    @product = Product.find_by(id: params[:qc_report][:product_id])
    return fail('Could not find product') if @product.nil?
    return fail("#{product.name} is inactive") if @product.deprecated?
    return fail("#{product.name} does not have any stock criteria set") if @product.stock_criteria.nil?
    true
  end

  def fail(message)
    redirect_to :back, alert: message
    false
  end

  def conditions
    conds = {}
    conds[:study_id] = params[:study_id] if params[:study_id].present?
    conds[:product_criteria] = { product_id: params[:product_id] } if params[:product_id].present?
    conds[:state] = params[:state] if params[:state].present?
    conds
  end
end
