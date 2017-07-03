class PoolingsController < ApplicationController
  def new
    @pooling = Pooling.new(pooling_params)
  end

  def create
    @pooling = Pooling.new(pooling_params.merge(barcode_printer: params[:printer]))
    if @pooling.valid?
      @pooling.execute
      flash.update(@pooling.message)
      redirect_to new_pooling_path
    else
      flash.now[:error] = @pooling.errors.full_messages
      render :new
    end
  end

  def find_tags_clash
    @pooling = Pooling.new(pooling_params.merge(barcode_printer: params[:printer]))
    if @pooling.valid?
      flash[:notice] = 'No tags clashes found'
    else
      flash[:error] = @pooling.tags_clash_message || @pooling.errors.full_messages
    end
    render :new
  end

  def pooling_params
    params.require(:pooling).permit(:stock_mx_tube_required, :count, :barcode_printer, barcodes: []) if params[:pooling].present?
  end
end
