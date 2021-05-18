# frozen_string_literal: true

# Used in the flexible cherrypick pipeline layout page
class MachineBarcodesController < ApplicationController
  def show
    asset = Labware.with_barcode(params[:id]).first
    summary = asset.present? ? asset.summary_hash : {}
    status = asset.present? ? 200 : 404
    respond_to { |format| format.json { render json: summary, status: status } }
  end
end
