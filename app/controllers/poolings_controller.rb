class PoolingsController < ApplicationController
  def new
    @pooling = Pooling.new
  end

  def create
    @pooling = Pooling.new(pooling_params.merge(barcode_printer: params[:printer]))
    if @pooling.valid?
      @pooling.execute
      flash[:notice] = @pooling.success + @pooling.print_job_message[:notice].to_s
      flash[:error] = @pooling.print_job_message[:error] if @pooling.print_job_message[:error].present?
      redirect_to new_pooling_path
    else
      flash.now[:error] = @pooling.errors.full_messages
      render :new
    end
  end

  def pooling_params
    params.require(:pooling).permit(:stock_mx_tube_required, :count, :barcode_printer, barcodes: [])
  end
end
