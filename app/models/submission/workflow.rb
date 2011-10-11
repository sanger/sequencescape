require 'exception/quota_exception'

class Submission::Workflow < ActiveRecord::Base
  has_many :request_types
  has_many :submissions
  has_many :items

  def self.default_workflow
    self.find_by_name('Next-gen sequencing') or raise StandardError, "Cannot find submission workflow 'Next-gen sequencing'"
  end

  FIELDS_TO_WORKFLOWS = {
    'Microarray genotyping' => [
      # Project metadata fields
      'project.metadata.gt_committee_tracking_id'
    ],
    'Next-gen sequencing'   => [
      # Project metadata fields
      'project.metadata.project_manager_id',
      'project.metadata.funding_comments',
      'project.metadata.collaborators',
      'project.metadata.external_funding_source'
    ]
  }.inject(Hash.new { |h,k| h[k] = [] }) do |fields_to_workflows,(workflow, acceptable_fields)|
    fields_to_workflows.tap do
      acceptable_fields.each do |field|
        fields_to_workflows[field] << workflow
      end
    end
  end

  def visible_attribute?(field_path)
    workflows_accepting_field = FIELDS_TO_WORKFLOWS[field_path.join('.')]
    return (workflows_accepting_field.blank? || workflows_accepting_field.include?(self.name))
  end
end
