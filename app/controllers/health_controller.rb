# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# Provides a simple endpoint for monitoring server status
class HealthController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :login_required, except: [:index]

  def index
    @monitor = Health.new

    respond_to do |format|
      format.json { render json: @monitor, status: @monitor.status }
    end
  end
end
