# frozen_string_literal: true
# Provides a simple endpoint for monitoring server status
class HealthController < ApplicationController
  before_action :login_required, except: [:show]

  def show
    @monitor = Health.new

    respond_to { |format| format.json { render json: @monitor, status: @monitor.status } }
  end
end
