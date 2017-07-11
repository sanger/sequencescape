# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class Pipeline::GrouperForPipeline
  delegate :requests, :group_by_parent?, :group_by_submission?, to: :@pipeline

  def initialize(pipeline)
    @pipeline = pipeline
  end

  def all(selected_groups)
    conditions, variables = [], []
    selected_groups.each { |group, _| call(conditions, variables, group) }
    requests.order(:id).inputs(true).group_conditions(conditions, variables).group_requests.all
  end

  def count(selected_groups)
    conditions, variables = [], []
    selected_groups.each { |group, _| call(conditions, variables, group) }
    requests.inputs(true).group_conditions(conditions, variables).group_requests(group: grouping).count(:all)
  end

  private

  def call(conditions, variables, group)
    condition, keys = [], group.split(', ')
    if group_by_parent?
      condition << 'tca.container_id=?'
      variables << keys.first.to_i
    end
    if group_by_submission?
      condition << 'requests.submission_id=?'
      variables << keys.last.to_i
    end
    conditions << "(#{condition.join(" AND ")})"
  end

  def grouping
    grouping = []
    grouping << 'tca.container_id' if group_by_parent?
    grouping << 'requests.submission_id' if group_by_submission?
    grouping.join(',')
  end
end
