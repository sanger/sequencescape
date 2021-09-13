# frozen_string_literal: true
# Some {Pipeline pipelines} group requests together in the inbox, such that all requests
# in a plate and submission MUST be selected together.
# This takes the selected checkboxes and splits the information back out to the
# individual requests.
class Pipeline::GrouperByParentAndSubmission < Pipeline::GrouperForPipeline
  def all(selected_groups)
    queries = selected_groups.map { |group| extract_conditions(group) }

    # We build out own OR query by hand, as the built in Rails support will raise
    # a SystemStackError when face with a large number of `selected_groups`.
    # This is beacuse it processes the various conditions in a recursive manner.
    # For example, the following is throwing a `SystemStackError`.
    # @example (2...800).reduce(Request.where(id:1)) {|a,b| a.or(Request.where(id: b)) }.to_sql
    # Be a little cautious before making changes to use native arel, as internal
    # changes in arel, and the stack limits of the Ruby VM, may cause the problem
    # to trigger at different levels. We probably only want to switch to the
    # native function when it no longer builds its queries recursively. (Or when
    # ruby handles recursive method calls differently.)
    combined_queries = queries.join(' OR ').presence || 'FALSE'
    base_scope.where(combined_queries)
  end

  private

  # This extracts the container/submission values from the group
  # and uses them to generate a query.
  def extract_conditions(group)
    labware_id, submission_id = group.split(', ')

    # This is a Rails provided method to sanatize
    # input into sql queries. While calling .to_i on
    # our inputs should render then safe, an extra
    # layer of caution can't harm and should protect
    # us against future changes intoroducing risks.
    requests.sanitize_sql(
      ['(`receptacles`.`labware_id` = ? AND `requests`.`submission_id` = ?)', labware_id.to_i, submission_id.to_i]
    )
  end
end
