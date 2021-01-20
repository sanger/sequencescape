class Admin::DelayedJobsController < ApplicationController # rubocop:todo Style/Documentation
  authorize_resource

  def index
    @jobs = Delayed::Job.all
  end
end
