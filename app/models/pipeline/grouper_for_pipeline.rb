class Pipeline::GrouperForPipeline
  include Pipeline::Grouper

  def call(conditions, variables, group)
    condition, keys = [], group.split(', ')
    if group_by_parent?
      condition << "tca.container_id=?"
      variables << keys.first.to_i
    end
    if group_by_submission?
      condition << "requests.submission_id=?"
      variables << keys.last.to_i
    end
    conditions << "(#{condition.join(" AND ")})"
  end
  private :call

  def grouping
    grouping = []
    grouping << 'tca.container_id' if group_by_parent?
    grouping << 'requests.submission_id' if group_by_submission?
    grouping.join(',')
  end
  private :grouping
end
