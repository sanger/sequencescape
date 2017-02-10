# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.
module Workflowed
  def self.included(base)
    base.class_eval do
      belongs_to :workflow, class_name: 'Submission::Workflow'
      scope :for_workflow, ->(workflow) { where(workflow_id: workflow) }
    end
  end
end
