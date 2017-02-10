# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

# SubmissionPools are designed to view submissions in the context of a particular asset
class SubmissionPool < ActiveRecord::Base
  module Association
    module Plate
      def self.included(base)
        base.class_eval do
          # Rails 4 takes scopes as second argument, we can probably also tidy up and remove the counter_sql
          # as it is the :group by seems to throw rails, and distinct will throw off out count.
          has_many :submission_pools, ->() { select('submissions.*, requests.id AS outer_request_id').group('submissions.id').uniq },
            through: :well_requests_as_target do

              def count(*args)
                # Horrid hack due to the behaviour of count with a group_by
                # We can't use uniq alone, as the outer_request_id makes
                # the vairous rows unique.
                s = super
                return s if s.is_a?(Numeric)
                s.length
              end

              def size(*args)
                # Horrid hack due to the behaviour of count with a group_by
                # We can't use uniq alone, as the outer_request_id makes
                # the vairous rows unique.
                s = super
                return s if s.is_a?(Numeric)
                s.length
              end
          end

          def submission_pools
            SubmissionPool.for_plate(self)
          end
        end
      end
    end
  end

  self.table_name = 'submissions'

  belongs_to :outer_request, class_name: 'Request'
  has_many :tag2_layout_template_submissions, class_name: 'Tag2Layout::TemplateSubmission', foreign_key: 'submission_id'
  has_many :tag2_layout_templates, through: :tag2_layout_template_submissions

  scope :include_uuid, ->() {}
  scope :include_outer_request, ->() { includes(:outer_request) }

  scope :for_plate, ->(plate) {
    stock_plate = plate.stock_plate

    return where('false') if stock_plate.nil?

    select('submissions.*, MIN(our.id) AS outer_request_id')
    .joins([
      'LEFT JOIN requests AS our ON our.submission_id = submissions.id',
      'LEFT JOIN container_associations as spw ON spw.content_id = our.asset_id'
    ])
    .where([
      'spw.container_id =? AND our.sti_type NOT IN (?) AND our.state IN (?)',
      stock_plate.id,
      [TransferRequest, *TransferRequest.descendants].map(&:name),
      Request::Statemachine::ACTIVE
    ])
    .group('submissions.id')
  } do

      def count(*_args)
        # Horrid hack due to the behaviour of count with a group_by
        # We can't use uniq alone, as the outer_request_id makes
        # the vairous rows unique.
        s = super(:id)
        return s if s.is_a?(Numeric)
        s.length
      end

      def size(*args)
        # Horrid hack due to the behaviour of count with a group_by
        # We can't use uniq alone, as the outer_request_id makes
        # the vairous rows unique.
        s = super
        return s if s.is_a?(Numeric)
        s.length
      end
  end

  def plates_in_submission
    outer_request.submission_plate_count
  end

  def used_tag2_layout_templates
    tag2_layout_templates.map { |template| { 'uuid' => template.uuid, 'name' => template.name } }
  end
end
