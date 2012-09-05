class Batches::RequestsController < ApplicationController

  def index
    requests = Batch.find(params[:batch_id]).requests
    respond_to do |format|
      format.xml { render :xml => requests.to_xml }
    end
  end

end
