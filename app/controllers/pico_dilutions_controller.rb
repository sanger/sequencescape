#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class PicoDilutionsController < ApplicationController

  before_action :login_required, :except => [:index]

  def index
    pico_dilutions = DilutionPlate.with_pico_children.page(params[:page]).order(id: :desc).per_page(500)
    pico_dilutions_hash = PicoDilutionPlate.index_to_hash(pico_dilutions)

    respond_to do |format|
      format.xml  { render :xml  => pico_dilutions_hash, :root => 'records' }
      format.json { render :json => pico_dilutions_hash }
    end
  end
end
