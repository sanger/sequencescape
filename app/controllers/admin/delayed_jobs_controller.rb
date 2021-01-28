# frozen_string_literal: true

# Provides a list of currently registered delayed jobs
class Admin::DelayedJobsController < ApplicationController
  authorize_resource class: 'Delayed::Job'

  def index
    @jobs = Delayed::Job.all
  end
end
