class BillingReportsController < ApplicationController

  def new
    @billing_report = Billing::Report.new(billing_report_params)
  end

  def create
    fields_attributes = YAML.load_file(Rails.root.join('config', 'billing', 'fields.yml')).with_indifferent_access
    fields = Billing::FieldsList.new(fields_attributes)
    @billing_report = Billing::Report.new(billing_report_params.merge(fields: fields))
    if @billing_report.valid?
      send_data @billing_report.data,
                type: 'text',
                filename: "#{@billing_report.file_name}.bif",
                disposition: 'attachment'
    else
      flash[:error] = @billing_report.errors.full_messages.join(', ')
      render :new
    end

  end

  def billing_report_params
    params.require(:billing_report).permit(:start_date, :end_date, :file_name) if params[:billing_report].present?
  end

end