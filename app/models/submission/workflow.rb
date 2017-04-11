# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Submission::Workflow < ActiveRecord::Base
  has_many :request_types
  has_many :orders
  has_many :items

  def self.default_workflow
    find_by(name: 'Next-gen sequencing') or raise StandardError, "Cannot find submission workflow 'Next-gen sequencing'"
  end

  FIELDS_TO_WORKFLOWS = {
    'Microarray genotyping' => [
      # Project metadata fields
      'project.metadata.gt_committee_tracking_id'
    ],
    'Next-gen sequencing' => [
      # Project metadata fields
      'project.metadata.project_manager_id',
      'project.metadata.funding_comments',
      'project.metadata.collaborators',
      'project.metadata.external_funding_source'
    ]
  }.inject(Hash.new { |h, k| h[k] = [] }) do |fields_to_workflows, (workflow, acceptable_fields)|
    fields_to_workflows.tap do
      acceptable_fields.each do |field|
        fields_to_workflows[field] << workflow
      end
    end
  end

  def visible_attribute?(field_path)
    workflows_accepting_field = FIELDS_TO_WORKFLOWS[field_path.join('.')]
    (workflows_accepting_field.blank? || workflows_accepting_field.include?(name))
  end
end
