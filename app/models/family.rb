# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Family < ActiveRecord::Base
  belongs_to :task
  belongs_to :workflow, class_name: 'LabInterface::Workflow', foreign_key: :pipeline_workflow_id
  has_many :assets

  acts_as_descriptable :active
end
