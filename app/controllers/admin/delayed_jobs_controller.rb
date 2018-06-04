
class Admin::DelayedJobsController < ApplicationController
  before_action :admin_login_required

  def index
    @jobs = Delayed::Job.all
  end
end
