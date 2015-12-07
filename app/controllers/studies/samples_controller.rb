#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Studies::SamplesController < ApplicationController
#WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
#It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_filter :evil_parameter_hack!

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
