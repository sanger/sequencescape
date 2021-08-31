# frozen_string_literal: true
# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a submission MUST be selected together.
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
class Pipeline::GrouperBySubmission < Pipeline::GrouperForPipeline
  def all(selected_groups)
    submission_ids = selected_groups.map { |group| extract_conditions(group) }
    base_scope.where(submission_id: submission_ids)
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    keys = group.split(', ')
    keys.last.to_i
  end
end
