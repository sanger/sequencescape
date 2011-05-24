class Search::FindUserBySwipcardCode < Search
  def scope(criteria)
    User.with_swipcard_code(criteria['swipcard_code'])
  end
end
