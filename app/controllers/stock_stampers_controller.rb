# frozen_string_literal: true
class StockStampersController < ApplicationController
  def new
    @stock_stamper = StockStamper.new
  end

  def create
    @stock_stamper = StockStamper.new(stock_stamper_params)
    if @stock_stamper.valid?
      @stock_stamper.execute
      flash.update(@stock_stamper.message)
      flash.discard
    else
      flash.now[:error] = @stock_stamper.errors.full_messages
      render :new
    end
  end

  def generate_tecan_file
    send_data params[:file_content],
              type: 'text/plain',
              filename: "stock_stamper_#{params[:plate_barcode]}.gwl",
              disposition: 'attachment'
  end

  def print_label
    print_job =
      LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::AssetRedirect, printables: params[:printable])
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
    redirect_to new_stock_stamper_path
  end

  def stock_stamper_params
    params
      .require(:stock_stamper)
      .permit(
        :user_barcode,
        :source_plate_barcode,
        :source_plate_type_name,
        :destination_plate_barcode,
        :destination_plate_type_name,
        :overage
      )
  end
end
