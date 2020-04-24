class QuadStampController < ApplicationController

  before_action :set_plate_creators, only: [:new, :create]
  before_action :set_barcode_printers, only: [:new, :create]

  def new
    # @quad_stamp = QuadStamp.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @creator = QuadCreator.new(parents: parents_hash, target_purpose: target_purpose, user: user)


  end

  def set_plate_creators
    @plate_creators = Plate::Creator.order(:name)
  end

  def set_barcode_printers
    @barcode_printers = BarcodePrinterType384Plate.first.barcode_printers
    @barcode_printers = BarcodePrinter.order('name asc') if @barcode_printers.blank?
  end

end