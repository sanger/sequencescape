# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class LabwhereReceptionsController < ApplicationController
  before_action :login_required, except: [:index, :create]

  def index
    @labwhere_reception = LabwhereReception.new(params[:user_code], params[:location_barcode], [])
  end

  def create
    # user_barcode,location_barcode,asset_barcodes
    input = params[:labwhere_reception] || {}

    lwr = LabwhereReception.new(input[:user_code], input[:location_barcode], input[:barcodes])
    if lwr.save
      flash[:notice] = 'Locations updated!'
    else
      flash[:error] = lwr.errors.full_messages.join('; ')
    end
    redirect_to labwhere_receptions_path
  end
end
