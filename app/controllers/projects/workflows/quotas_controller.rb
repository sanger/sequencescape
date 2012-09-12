class Projects::Workflows::QuotasController < ApplicationController
  before_filter :discover_project, :discover_workflow
  # Quotas a managed via /admin/project/
  def send_request
    EventFactory.quota_update(@project, current_user, params[:limits], params[:comment])
    flash[:notice] = "Your quota update request has been sent"
    redirect_to project_url(@project)
  end

  def update_request
    @request_types = @workflow.request_types
  end

  private
  def discover_project
    @project = Project.find(params[:project_id])
  end

  def discover_workflow
    @workflow = Submission::Workflow.find(params[:workflow_id])
  end
end
