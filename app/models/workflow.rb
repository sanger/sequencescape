# frozen_string_literal: true

# A workflow describes a series of Tasks which are processed as
# part of taking a Batch through a Pipeline
class Workflow < ApplicationRecord
  has_many :tasks, -> { order('sorted') }, dependent: :destroy, foreign_key: :pipeline_workflow_id, inverse_of: :workflow

  belongs_to :pipeline, inverse_of: :workflow
  validates :pipeline_id, uniqueness: { message: 'only one workflow per pipeline!' }

  validates :name, uniqueness: { case_sensitive: false }

  def batch_limit?
    item_limit.present?
  end

  def source_is_internal?
    locale == 'Internal'
  end

  def assets
    []
  end

  def deep_copy(suffix = '_dup', skip_pipeline = false)
    dup.tap do |new_workflow|
      ActiveRecord::Base.transaction do
        new_workflow.name = new_workflow.name + suffix
        new_workflow.tasks = tasks.map do |task|
          new_task = task.dup
          new_task.descriptors = task.descriptors.map(&:dup)
          new_task
        end
        new_workflow.pipeline = nil
        new_workflow.save!

        # copy of the pipeline
        unless skip_pipeline
          new_workflow.pipeline = pipeline.dup
          new_workflow.pipeline.request_types = pipeline.request_types
          new_workflow.pipeline.name += suffix
          new_workflow.pipeline.save!
        end
      end
    end
  end
end
