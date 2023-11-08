# frozen_string_literal: true
class BarcodePrintersController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  authorize_resource

  def index
    @barcode_printers = BarcodePrinter.all

    respond_to { |format| format.html }
  end

  def show
    @barcode_printer = BarcodePrinter.find(params[:id])

    respond_to { |format| format.html }
  end

  def new
    @barcode_printer = BarcodePrinter.new

    respond_to { |format| format.html }
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
        format.html { render action: 'new' }
      end
    end
  end

  def update # rubocop:todo Metrics/AbcSize
    @barcode_printer = BarcodePrinter.find(params[:id])
    @barcode_printer.barcode_printer_type = BarcodePrinterType.find(params[:barcode_printer_type_id])

    respond_to do |format|
      if @barcode_printer.update(params[:barcode_printer])
        flash[:notice] = 'Barcode Printer was successfully updated.'
        format.html { redirect_to(barcode_printers_url) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @barcode_printer = BarcodePrinter.find(params[:id])
    @barcode_printer.destroy

    respond_to { |format| format.html { redirect_to(barcode_printers_url) } }
  end
end
