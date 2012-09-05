class Samples::StudiesController < ApplicationController

  def index
    studies = Sample.find(params[:sample_id]).studies
    respond_to do |format|
      format.xml { render :xml => studies.to_xml }
    end
  end

end
