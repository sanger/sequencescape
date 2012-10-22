class Search::FindIlluminaBPlatesForUser < Search::FindIlluminaBPlates
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    super.for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
  end
end
