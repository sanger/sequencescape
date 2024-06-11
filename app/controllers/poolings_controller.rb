# frozen_string_literal: true

# ALlows the creation of a new {MultiplexedLibraryTube} from one or more arbitrary {Tube tubes}
class PoolingsController < ApplicationController
  def new
    @pooling = Pooling.new(pooling_params)
  end

  def create # rubocop:todo Metrics/AbcSize
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

  def pooling_params
    return unless params[:pooling].present?
      params.require(:pooling).permit(:stock_mx_tube_required, :count, :barcode_printer, barcodes: [])
    
  end
end
