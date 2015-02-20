#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Samples::StudiesController < ApplicationController

  def index
    studies = Sample.find(params[:sample_id]).studies
    respond_to do |format|
      format.xml { render :xml => studies.to_xml }
    end
  end

end
