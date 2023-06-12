# frozen_string_literal: true

# Will construct a project
class UatActions::GenerateProject < UatActions
  self.title = 'Generate project'
  self.description = 'Generate a simple project with the provided name.'

  form_field :project_name, :text_field, label: 'Project Name', help: 'The name of the project.'

  form_field :project_cost_code, :text_field, label: 'Project Cost Code', help: 'The cost code for the project.'

  def self.default
    new(project_name: UatActions::StaticRecords.project.name, project_cost_code: '1234')
  end

  def perform
    project = create_project
    print_report(project)

    true
  end

  def create_project
    Project
      .create_with(project_metadata_attributes: { project_cost_code: project_cost_code })
      .find_or_create_by!(name: project_name)
  end

  private

  def print_report(project)
    report['project_id'] = project.id
  end
end
