# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class SequenomQcPlatesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  def new
    @barcode_printers  = BarcodePrinterType.find_by(name: '384 Well Plate').barcode_printers
    @barcode_printers  = BarcodePrinter.order(:name) if @barcode_printers.blank?
    @input_plate_names = input_plate_names
  end

  def create
    @input_plate_names = input_plate_names
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
          plate_prefix: params[:plate_prefix],
          gender_check_bypass: gender_check_bypass,
          user_barcode: user_barcode,
          purpose: PlatePurpose.find_by(name: 'Sequenom')
        )
        # Need to be done before saving the plate
        valid = input_plate_names && sequenom_qc_plate.compute_and_set_name(input_plate_names)
        errors = sequenom_qc_plate.errors.inject({}) { |h, (k, v)| h.update(k => v) }

        saved = sequenom_qc_plate.save
        sequenom_qc_plate.connect_input_plates(input_plate_names.values.reject(&:blank?))

        if saved and valid and sequenom_qc_plate.add_event_to_stock_plates(user_barcode)
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
        flash[:error] = bad_plate.errors.full_messages || 'Failed to create Sequenom QC Plate'
        format.html { render :new }
      else
        print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                              LabelPrinter::Label::SequenomPlateRedirect,
                                              plates: new_plates, count: 3, plate384: barcode_printer.plate384_printer?)

        # and redirect to a fresh page with an appropriate flash[:notice]

        first_plate = new_plates.first

        if print_job.execute
          flash[:notice] = "Sequenom #{first_plate.plate_prefix} Plate #{first_plate.name} successfully created and labels printed."
        else
          flash[:error] = print_job.errors.full_messages.join('; ')
        end

        format.html { redirect_to new_sequenom_qc_plate_path }
      end
    end
  end

  def index
    @sequenom_qc_plates = SequenomQcPlate.page(params[:page]).order(created_at: :desc)
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
    (1..4).each { |i| input_plate_names[i] = params[:input_plate_names].try(:[], i.to_s) || '' }
    input_plate_names
  end
end
