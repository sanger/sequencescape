#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class PicoDilutionsController < ApplicationController
  before_filter :login_required, :except => [:index]

  def index
    pico_dilutions = PicoDilutionPlate.paginate :page => params[:page], :order => 'id DESC', :per_page => 500
    pico_dilutions_hash = PicoDilutionPlate.index_to_hash(pico_dilutions)

    respond_to do |format|
      format.xml  { render :xml  => pico_dilutions_hash }
      format.json { render :json => pico_dilutions_hash }
    end
  end
end
