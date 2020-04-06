class BulkPrintController < ApplicationController

  attr_accessor :labware

  def index
    labware_ids_string = params[:labware]
    return if labware_ids_string.blank?

    labware_ids = labware_ids_string.split(',').map { |id| id.strip.to_i }

    @labware = Labware.find(labware_ids)
  end
end
