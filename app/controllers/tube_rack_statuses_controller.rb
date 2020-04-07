# frozen_string_literal: true

# Controller to display the status of a tube rack
class TubeRackStatusesController < ApplicationController
  before_action :login_required

  def index
    @tube_rack_statuses = TubeRackStatus.order(created_at: :desc).paginate(page: params[:page], per_page: 30)
  end
end
