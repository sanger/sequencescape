class StockStampersController < ApplicationController
  def new
    @stock_stamper = StockStamper.new
  end

  def create
    @stock_stamper = StockStamper.new(stock_stamper_params)
    if @stock_stamper.valid?
      @stock_stamper.generate_tecan_gwl_file_as_text
      @stock_stamper.create_asset_audit_event
      flash.now[:notice] = 'Success! You can generate the TECAN file now.'
    else
      flash.now[:error] = @stock_stamper.errors.full_messages
      render :new
    end
  end

  def generate_tecan_file
    send_data params[:file_content], type: 'text/plain',
                                     filename: "stock_stamper_#{params[:plate_barcode]}.gwl",
                                     disposition: 'attachment'
  end

  def stock_stamper_params
    params.require(:stock_stamper).permit(:user_barcode, :source_plate_barcode, :source_plate_type_name, :destination_plate_barcode, :destination_plate_type_name, :overage)
  end
end
