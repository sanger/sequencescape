#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Batches::RequestsController < ApplicationController

  def index
    requests = Batch.find(params[:batch_id]).requests
    respond_to do |format|
      format.xml { render :xml => requests.to_xml }
    end
  end

end
