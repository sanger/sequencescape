#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
# Classes including this module are capable of grouping the requests for a pipeline in a
# specific manner.
module Pipeline::Grouper
  def self.included(base)
    base.delegate :requests, :group_by_parent?, :group_by_submission?, :to => :@pipeline
  end

  def initialize(pipeline)
    @pipeline = pipeline
  end

  def all(selected_groups)
    conditions, variables = [], []
    selected_groups.each { |group, _| call(conditions, variables, group) }
    requests.inputs(true).group_conditions(conditions, variables).group_requests(:all)
  end

  def count(selected_groups)
    conditions, variables = [], []
    selected_groups.each { |group, _| call(conditions, variables, group) }
    requests.inputs(true).group_conditions(conditions, variables).group_requests(:count, :group => grouping)
  end
end
