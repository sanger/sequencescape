class SubmissionPresenter
  attr_accessor :submission_template_id, :study_name, :project_name
  attr_reader :user

  def initialize(current_user)
    @user = current_user
  end

  def user_projects
    @user_projects ||= @user.sorted_project_names_and_ids.map(&:first)
  end

  def studies
    @studies ||= Study.all.map(&:name)
  end

  def templates
    @templates ||= SubmissionTemplate.all
  end
end

class SubmissionsController < ApplicationController

  def new
    @submission_presenter = SubmissionPresenter.new(current_user)
  end

  def create
  end
end
