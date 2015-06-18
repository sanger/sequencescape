#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

# SubmissionPools are designed to view submissions in the context of a particular asset
class SubmissionPool < ActiveRecord::Base

  module Association
    module Plate
      def self.included(base)
        base.class_eval do
          has_many :submission_pools, :finder_sql => %q{
              SELECT DISTINCT submissions.* FROM submissions
              INNER JOIN requests as tfr ON tfr.submission_id = submissions.id
              INNER JOIN container_associations as pw ON pw.content_id = tfr.target_asset_id
              WHERE pw.container_id = #{id};
            }
          # We override the default rails method, as the api attempts to inject pagination.
          # Meanwhile we need to still specify the association, as the api uses it to work
          # out the appropriate class.
          def submission_pools
            SubmissionPool.for_plate(self)
          end
        end
      end

    end
  end

  set_table_name('submissions')

  belongs_to :outer_request, :class_name => 'Request'
  has_many :tag2_layout_template_submissions, :class_name => 'Tag2Layout::TemplateSubmission', :foreign_key => 'submission_id'
  has_many :tag2_layout_templates, :through => :tag2_layout_template_submissions

  named_scope :include_uuid, { }
  named_scope :include_outer_request, { :include => :outer_request}

  named_scope :for_plate, lambda {|plate|

    stock_plate = plate.stock_plate

    return {:conditions=>'false'} if stock_plate.nil?

    {
      :select => 'submissions.*, our.id AS outer_request_id',
      :joins  => [
        'LEFT JOIN requests as our ON our.submission_id = submissions.id',
        'LEFT JOIN container_associations as spw ON spw.content_id = our.asset_id'
      ],
      :conditions => [
        'spw.container_id =? AND our.sti_type NOT IN (?) AND our.state IN (?)',
        stock_plate.id,
        [TransferRequest,*Class.subclasses_of(TransferRequest)].map(&:name),
        Request::Statemachine::ACTIVE
      ],
      :group => 'submission_id'
    }
  }

  def plates_in_submission
    outer_request.submission_plate_count
  end

  def used_tag2_layout_templates
    tag2_layout_templates.map {|template| {"uuid"=>template.uuid,"name"=>template.name}}
  end

end
