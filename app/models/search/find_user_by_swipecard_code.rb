# frozen_string_literal: true
class Search::FindUserBySwipecardCode < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    User.with_swipecard_code(criteria['swipecard_code'])
  end
end
