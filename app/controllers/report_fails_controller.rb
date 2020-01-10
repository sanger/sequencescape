# frozen_string_literal: true

# Controller for reporting failed labware
class ReportFailsController < ApplicationController
  before_action :login_required, except: %i[index create]

  def index
    @report_fail = ReportFail.new(params[:user_code], params[:failure_id], [])
  end

  def create
    # user_barcode,failure_id,barcodes
    input = params[:report_fail] || {}

    @report_fail = ReportFail.new(input[:user_code],
                                  input[:failure_id],
                                  input[:barcodes])
    if @report_fail.save
      flash.now[:notice] = 'Failure saved'
    else
      flash.now[:error] = @report_fail.errors.full_messages.join('; ')
    end
  end
end
