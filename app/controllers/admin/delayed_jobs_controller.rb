class Admin::DelayedJobsController < ApplicationController
  before_filter :admin_login_required

  def index
    @jobs = Delayed::Job.all
  end

end
