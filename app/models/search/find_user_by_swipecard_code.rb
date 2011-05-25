class Search::FindUserByswipecardCode < Search
  def scope(criteria)
    User.with_swipecard_code(criteria['swipecard_code'])
  end
end
