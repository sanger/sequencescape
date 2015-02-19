#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class SampleLogisticsController < ApplicationController
  before_filter :slf_gel_login_required, :only => [:index, :qc_overview]

  def qc_overview
    @stock_plates = Plate.qc_started_plates.paginate :page => params[:page], :per_page => 500
  end
end
