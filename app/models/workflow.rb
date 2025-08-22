# frozen_string_literal: true

# A workflow describes a series of Tasks which are processed as
# part of taking a Batch through a Pipeline
class Workflow < ApplicationRecord
  has_many :tasks,
           lambda { order(:sorted) },
           dependent: :destroy,
           foreign_key: :pipeline_workflow_id,
           inverse_of: :workflow

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
end
