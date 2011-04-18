class Studies::SamplesController < ApplicationController

  def index
    @study = Study.find(params[:study_id])
    @samples = @study.samples.all(:order => "created_at ASC")

    respond_to do |format|
      format.html
      format.json { render :json => @samples.to_json }
      format.xml  { render :xml => @samples.to_xml }
    end
  end
end
