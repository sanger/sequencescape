# frozen_string_literal: true
# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a plate MUST be selected together.
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
class Pipeline::GrouperByParent < Pipeline::GrouperForPipeline
  def all(selected_groups)
    labware_ids = selected_groups.map { |group| extract_conditions(group) }
    base_scope.where('receptacles.labware_id' => labware_ids)
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    keys = group.split(', ')
    keys.first.to_i
  end
end
