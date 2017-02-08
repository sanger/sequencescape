# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class LabInterface::Workflow < ActiveRecord::Base
  has_many :tasks, ->() { order('sorted') }, dependent: :destroy, foreign_key: :pipeline_workflow_id
  has_many :families

  belongs_to :pipeline, inverse_of: :workflow
  validates_uniqueness_of :pipeline_id, message: 'only one workflow per pipeline!'

  validates_uniqueness_of :name

  def has_batch_limit?
    !item_limit.blank?
  end

  def controls
    families
  end

  def source_is_external?
    locale == 'External' ? true : false
  end

  def source_is_internal?
    locale == 'Internal' ? true : false
  end

  def assets
    collection = []
    tasks.each do |task|
      task.families.each do |family|
        collection.push family
      end
    end
    collection
  end

  def deep_copy(suffix = '_dup', skip_pipeline = false)
    dup.tap do |new_workflow|
      ActiveRecord::Base.transaction do
        new_workflow.name = new_workflow.name + suffix
        new_workflow.tasks = tasks.map do |task|
          new_task = task.dup
          new_task.descriptors = task.descriptors.map do |descriptor|
            descriptor.dup
          end
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

  def change_sorter_of_all_tasks(value)
    return nil if tasks.nil?
    tasks.each do |task|
      next if task.sorted + value < 0
      task.sorted = task.sorted + value
      task.save
    end
    true
  end
end
