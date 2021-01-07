class Search::FindPulldownPlatesForUser < Search::FindPulldownPlates # rubocop:todo Style/Documentation
  def scope(criteria)
    super.for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
  end
end
