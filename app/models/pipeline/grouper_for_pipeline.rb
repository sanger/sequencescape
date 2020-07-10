# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a submission or plate MUST be selected together
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
class Pipeline::GrouperForPipeline
  delegate :requests, :group_by_parent?, :group_by_submission?, to: :@pipeline

  LABWARE_ID_COLUMN = 'receptacles.labware_id'.freeze

  def initialize(pipeline)
    @pipeline = pipeline
  end

  def base_scope
    requests.order(:id)
            .ready_in_storage
            .full_inbox
            .select('requests.*')
  end

  def all(selected_groups)
    queries = selected_groups.map { |group| extract_conditions(group) }
    base_scope.where(queries.join(' OR '))
  end

  private

  def query_string
    if group_by_parent? && group_by_submission?
      '(`requests`.`submission_id` = :submission_id AND `receptacles`.`labware_id` = :labware_id)'
    elsif group_by_parent?
      '(`receptacles`.`labware_id` = :labware_id)'
    elsif group_by_submission?
      '(`requests`.`submission_id` = :submission_id)'
    else
      raise 'Invalid Grouper'
    end
  end

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    condition = {}.tap do |building_condition|
      keys = group.split(', ')
      building_condition[:labware_id] = keys.first.to_i if group_by_parent?
      building_condition[:submission_id] = keys.last.to_i if group_by_submission?
    end
    # base_scope.where(condition)
    requests.sanitize_sql(
      [
        '(`requests`.`submission_id` = :submission_id AND `receptacles`.`labware_id` = :labware_id)',
        condition
      ]
    )
  end
end
