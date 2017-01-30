class StockStampersController < ApplicationController

# WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
# It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def new
  end

  def create
    stock_stamper = StockStamper.new(params[:stock_stamper])
    if stock_stamper.valid?
      file_content = stock_stamper.generate_tecan_gwl_file_as_text
      stock_stamper.create_asset_audit_event
      send_data file_content, type: "text/plain",
        filename: "stock_stamper_#{stock_stamper.source_plate.ean13_barcode}.gwl",
        disposition: 'attachment'
    else
      flash[:error] = stock_stamper.errors.full_messages
      # redirect_to new_stock_stamper_path
      render :new
    end
  end

end