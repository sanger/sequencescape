class BillingReportsController < ApplicationController # rubocop:todo Style/Documentation
  def new
    @billing_report = Billing::Report.new(billing_report_params)
  end

  def create
    @billing_report = Billing::Report.new(billing_report_params.merge(fields: Billing.configuration.fields))
    if @billing_report.valid?
      send_data @billing_report.data,
                type: 'text',
                filename: "#{@billing_report.file_name}.bif",
                disposition: 'attachment'
    else
      flash.now[:error] = @billing_report.errors.full_messages.join(', ')
      render :new
    end
  end

  def billing_report_params
    params.require(:billing_report).permit(:start_date, :end_date, :file_name) if params[:billing_report].present?
  end
end
