class BarcodePrintersController < ApplicationController

  before_filter :admin_login_required

  def index
    @barcode_printers = BarcodePrinter.find(:all)

    respond_to do |format|
      format.html
    end
  end

  def show
    @barcode_printer = BarcodePrinter.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    @barcode_printer = BarcodePrinter.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @barcode_printer = BarcodePrinter.find(params[:id])
  end

  def create
    @barcode_printer = BarcodePrinter.new(params[:barcode_printer])
    @barcode_printer.barcode_printer_type = BarcodePrinterType.find(params[:barcode_printer_type_id])

    respond_to do |format|
      if @barcode_printer.save
        flash[:notice] = 'Barcode Printer was successfully created.'
        format.html { redirect_to(barcode_printers_url) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @barcode_printer = BarcodePrinter.find(params[:id])
    @barcode_printer.barcode_printer_type = BarcodePrinterType.find(params[:barcode_printer_type_id])

    respond_to do |format|
      if @barcode_printer.update_attributes(params[:barcode_printer])
        flash[:notice] = 'Barcode Printer was successfully updated.'
        format.html { redirect_to(barcode_printers_url) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @barcode_printer = BarcodePrinter.find(params[:id])
    @barcode_printer.destroy

    respond_to do |format|
      format.html { redirect_to(barcode_printers_url) }
    end
  end
  # This module define common behavior used by other controller to print things
  module Print
  def print_asset_labels(succes_url, failure_url)
    debugger
    assets = params[:printables]
    prefix = nil
    unless assets.nil?
      printables = []
      assets = assets.keys
      assets.sort{ |a,b| b.to_i <=> a.to_i }.each do |id|
        asset = Asset.find(id)
        prefix = asset.prefix
        unless asset.barcode.present?
        asset.barcode = AssetBarcode.new_barcode
        asset.save!
        end
        printables.push PrintBarcode::Label.new({ :number => asset.barcode, :study => "#{asset.tube_name}", :prefix => prefix, :suffix => "" })
       end

       unless printables.empty?
         BarcodePrinter.print(printables, params[:printer], prefix)
      end
    end
    flash[:notice] = "Your labels have been sent to printer #{params[:printer]}."
    redirect_to succes_url

    rescue SOAP::FaultError
    logger.error($!)
    flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
    redirect_to failure_url
  end
  end
end
