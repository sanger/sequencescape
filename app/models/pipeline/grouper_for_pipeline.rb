class Pipeline::GrouperForPipeline
  delegate :requests, :group_by_parent?, :group_by_submission?, to: :@pipeline

  def initialize(pipeline)
    @pipeline = pipeline
  end

  def all(selected_groups)
    conditions, variables = [], []
    selected_groups.each_key { |group| extract_conditions(conditions, variables, group) }
    requests.order(:id).inputs(true).group_conditions(conditions, variables).group_requests.all
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to populate the conditionas and variables arrays.
  # WARNING: This method mutates the conditions and variables arrays.
  # We can improve this drastically after the rails 5 update, as we can use
  # or, rather than building our own or through group_conditions
  def extract_conditions(conditions, variables, group)
    condition = []
    keys = group.split(', ')
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
