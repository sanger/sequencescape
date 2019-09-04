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
    selected_groups.map { |group| extract_conditions(group) }
                   .reduce { |scope, query| scope.or(query) }
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    condition = {}.tap do |building_condition|
      keys = group.split(', ')
      building_condition[LABWARE_ID_COLUMN] = keys.first.to_i if group_by_parent?
      building_condition[:submission_id] = keys.last.to_i if group_by_submission?
    end
    base_scope.where(condition)
  end
end
