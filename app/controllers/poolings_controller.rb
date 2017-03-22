class PoolingsController < ApplicationController
  def new
    @pooling = Pooling.new
  end

  def create
    @pooling = Pooling.new(pooling_params)
    if @pooling.valid?
      @pooling.execute
      flash[:notice] = 'Samples were transferred successfully'
    else
      flash.now[:error] = @pooling.errors.full_messages
    end
    render :new
  end

  def pooling_params
    params.require(:pooling).permit(:stock_mx_tube_required, barcodes: [])
  end
end
