class PicoSetResultsController < ApplicationController
  before_filter :login_required, :except => [:create]

  # TODO This should be an update method not create
  # TODO Refactor. Create an object for pico_set_result
  def create
    pico_set_result = params[:pico_set_result]

    if pico_set_result
      pico_assay_plate = PicoAssayPlate.find_from_machine_barcode(pico_set_result[:assay_barcode])
    end

    respond_to do |format|
      # create method call using pico_assay_plate[:state] and use send for 2 method calls
      if pico_assay_plate && pico_assay_plate.upload_pico_results(pico_set_result[:state], pico_set_result[:wells])
        flash[:notice] = 'Updated concentrations'
        format.xml  { render :xml  => flash.to_xml, :status => :ok }
        format.json { render :json => flash.to_json, :status => :ok }
      else
        flash[:error] = "Couldn't upload results"
        format.xml  { render :xml  => flash.to_xml, :status => :unprocessable_entity }
        format.json { render :json => flash.to_json, :status => :unprocessable_entity }
      end
    end
  end
end
