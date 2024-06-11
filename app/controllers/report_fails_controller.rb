# frozen_string_literal: true

# Controller for reporting failed labware
class ReportFailsController < ApplicationController
  before_action :login_required, except: %i[index create]

  def index
    @report_fail = ReportFail.new(nil, nil, [])
  end

    def create # rubocop:todo Metrics/AbcSize
    @report_fail =
      ReportFail.new(
        params_for_report_fails[:user_code],
        params_for_report_fails[:failure_id],
        params_for_report_fails[:barcodes]
      )
    if @report_fail.save
      flash.now[:notice] = 'Failure saved'
    else
      flash.now[:error] = @report_fail.errors.full_messages.join('; ')
    end
  end

    protected

  def params_for_report_fails
    params.require(:report_fail).permit(:user_code, :failure_id, barcodes: [])
  end
end
