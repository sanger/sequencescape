# Provides a simple endpoint for monitoring server status
class HealthController < ApplicationController
  before_action :login_required, except: [:index]

  def show
    @monitor = Health.new

    respond_to do |format|
      format.json { render json: @monitor, status: @monitor.status }
    end
  end
end
