#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class SequenomQcPlatesController < ApplicationController
  def new
    @barcode_printers  = BarcodePrinterType.find_by_name("384 Well Plate").barcode_printers
    @barcode_printers  = BarcodePrinter.find(:all, :order => "name asc") if @barcode_printers.blank?
    @input_plate_names = input_plate_names()
  end

  def create
    @input_plate_names = input_plate_names()
    @barcode_printers  = BarcodePrinter.all
    barcode_printer    = BarcodePrinter.find(params[:barcode_printer][:id])
    number_of_barcodes = params[:number_of_barcodes].to_i
    input_plate_names   = params[:input_plate_names]
    user_barcode        = params[:user_barcode]

    # It's been decided that a blank dummy plate will be created for each barcode label required
    # Any information stored against the plate's wells should be passed through to the stock plate
    # so should be findable.
    new_plates = []

    # This will hold the first bad plate with errors preventing it's creation
    bad_plate  = nil

    ActiveRecord::Base.transaction do
      (1..number_of_barcodes).each do
        sequenom_qc_plate = SequenomQcPlate.new(
          :plate_prefix        => params[:plate_prefix],
          :gender_check_bypass => gender_check_bypass,
          :user_barcode        => user_barcode
        )
        #TODO: create a factory object

        # Need to be done before saving the plate
        valid = input_plate_names && sequenom_qc_plate.compute_and_set_name(input_plate_names)
        errors = sequenom_qc_plate.errors.inject({}) { |h, (k, v)| h.update(k=>v) }
        if sequenom_qc_plate.save and valid and sequenom_qc_plate.add_event_to_stock_plates(user_barcode)
          new_plates << sequenom_qc_plate
        else
          # If saving any of our new plates fails then catch that plate, for errors
          # and move straight on to sending a response
          bad_plate = sequenom_qc_plate
          errors.each do |att, value|
            bad_plate.errors.add(att, value)
          end
          break
        end
      end
    end

    respond_to do |format|
      if bad_plate
        # Something's gone wrong, render the errors on the first plate that failed
        flash[:error] = bad_plate.errors.full_messages || "Failed to create Sequenom QC Plate"
        format.html { render :new }
      else
        # Everything's tickity boo so...
        # print the a label for each plate we created
        new_plates.each { |p| p.print_labels(barcode_printer) }

        # and redirect to a fresh page with an appropriate flash[:notice]
        first_plate    = new_plates.first
        flash[:notice] = "Sequenom #{first_plate.plate_prefix} Plate #{first_plate.name} successfully created and labels printed."

        format.html { redirect_to new_sequenom_qc_plate_path }
      end
    end

  end

  def index
    @sequenom_qc_plates = SequenomQcPlate.paginate(:page => params[:page], :order => "created_at desc")
  end

  private
  # If the current user isn't allowed to bypass the geneder checks don't let them
  # even they're sneaky enough to try and send back the param value anyway!
  def gender_check_bypass
    if current_user.slf_manager? || current_user.manager_or_administrator?
      params[:gender_check_bypass]
    else
      false
    end
  end

  def input_plate_names
    input_plate_names = {}
    (1..4).each { |i| input_plate_names[i] = params[:input_plate_names].try(:[],i.to_s) || "" }
    input_plate_names
  end

end
