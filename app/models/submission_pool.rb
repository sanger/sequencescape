# frozen_string_literal: true
# SubmissionPools are designed to view submissions in the context of a particular asset
class SubmissionPool < ApplicationRecord
  module Association
    module Plate # rubocop:todo Style/Documentation
      def self.included(base)
        base.class_eval do
          has_many :submission_pools, -> { distinct }, through: :well_requests_as_target

          def submission_pools
            SubmissionPool.for_plate(self)
          end
        end
      end
    end
  end

  self.table_name = 'submissions'

  has_one :outer_request,
          lambda { order(id: :asc).where(state: Request::Statemachine::ACTIVE) },
          class_name: 'Request',
          foreign_key: :submission_id
  has_many :tag_layout_template_submissions, class_name: 'TagLayout::TemplateSubmission', foreign_key: 'submission_id'
  has_many :tag_layout_templates, through: :tag_layout_template_submissions
  has_many :tag2_layout_template_submissions, class_name: 'Tag2Layout::TemplateSubmission', foreign_key: 'submission_id'
  has_many :tag2_layout_templates, through: :tag2_layout_template_submissions

  scope :include_uuid, -> {  }
  scope :for_plate, ->(plate) { where(id: plate.all_submission_ids) }

  # JG [2018-10-12] LIMITATION: This currently uses the first request in a submission, so could cause
  # confusion if we have, say, cherry-picking requests upstream of library creation.
  # We currently have no submission templates like this active.
  # This value is used to work out if we have a cross-plate pool and therefore need
  # UDIs. Two things are likely to happen soon which make this concern redundant:
  # 1) We'll switch to UDIs only -> Actually there at time of writing, but there may be one more lot of 168s comming in
  # 2) Limber will be making the decision itself more directly
  # It was agreed with Jamie that it was more important to detect clashes than it was to handle unlikely
  # possible future scenarios.
  def plates_in_submission
    outer_request&.submission_plate_count || 0 # If all requests have been cancelled, we can ignore the submission.
  end

  def used_tag2_layout_templates
    tag2_layout_templates.map { |template| { 'uuid' => template.uuid, 'name' => template.name } }
  end

  def used_tag_layout_templates
    tag_layout_templates.map { |template| { 'uuid' => template.uuid, 'name' => template.name } }
  end
end
