class Admin::DelayedJobsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :admin_login_required

  def index
    @jobs = Delayed::Job.all
  end
end
