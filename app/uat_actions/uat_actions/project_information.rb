# frozen_string_literal: true

# Fetches project information for a project name.
class UatActions::ProjectInformation < UatActions
  self.title = 'Project information'
  self.description = 'Get project information for a project name.'
  self.category = :setup_and_test

  form_field :project_name, :text_field, label: 'Project Name', help: 'Fetches basic information for a project name.'

  validates :project_name, presence: { message: 'needs a value' }
  validates :project, presence: { message: 'could not be found' }

  def self.default
    new
  end

  def perform
    report[:project_name] = project_name
    return false if project.blank?

    report[:project_cost_code] = project.project_cost_code
    true
  end

  private

  def project
    @project = Project.find_by(name: project_name.to_s.strip) unless instance_variable_defined?(:@project)
    @project
  end
end
