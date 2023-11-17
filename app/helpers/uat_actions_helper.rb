# frozen_string_literal: true
module UatActionsHelper
  def grouped_and_sorted_uat_actions(uat_actions)
    uat_actions.group_by(&:category).sort_by { |category, _| UatActions::CATEGORY_LIST.index(category) }
  end
end
