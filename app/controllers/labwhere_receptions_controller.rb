# frozen_string_literal: true
class LabwhereReceptionsController < ApplicationController
  before_action :login_required, except: %i[index create]

  def index
    @labwhere_reception = LabwhereReception.new(params[:user_code], params[:location_barcode], [])
  end

  # rubocop: todo Metrics/AbcSize
  def create
    # user_barcode,location_barcode,asset_barcodes
    input = params[:labwhere_reception] || {}

    @labwhere_reception = LabwhereReception.new(input[:user_code], input[:location_barcode], input[:barcodes])
    if @labwhere_reception.save
      flash.now[:notice] = 'Locations updated!'
    else
      flash.now[:error] = @labwhere_reception.errors.full_messages.join('; ')
    end
    @labwhere_reception.user_code = ''
  end
  # rubocop: enable Metrics/AbcSize
end
