# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a plate and submission MUST be selected together.
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
class Pipeline::GrouperByParentAndSubmission < Pipeline::GrouperForPipeline
  def all(selected_groups)
    queries = selected_groups.map { |group| extract_conditions(group) }
    base_scope.where(queries.join(' OR '))
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    labware_id, submission_id = group.split(', ')
    requests.sanitize_sql(
      [
        '(`receptacles`.`labware_id` = ? AND `requests`.`submission_id` = ?)',
        labware_id.to_i, submission_id.to_i
      ]
    )
  end
end
