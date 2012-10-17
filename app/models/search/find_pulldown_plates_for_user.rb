class Search::FindPulldownPlatesForUser < Search::FindPulldownPlates
  def scope(criteria)
    super.for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
  end
end
